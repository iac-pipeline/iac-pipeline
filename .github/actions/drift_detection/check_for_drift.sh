set -xe
# change this value to fit for the higher environment, e.g. prod, staging, dev



echo "Checking for drift on $higher_branch for environment: $environment"

check_module_status() {
local changes_modules_to_check="$1"
local environment="$2"
for module in $(echo "$modules_changed" | jq -r '.[].path' | grep "$environment" ); do
    echo "Checking module: $module for drift"
    if [[ -d "$module" && -f "$module/terragrunt.hcl" ]]; then

        terragrunt run --all --json-out-dir /tmp/$environment/json plan --working-dir "$module" -out-dir /tmp/tfplan

        grab_json_body=$(jq -r '.resource_changes[] | select(.change.actions | index("no-op") | not) | "\(.address) → actions: \(.change.actions | join(", "))" ' /tmp/$environment/json/tfplan.json)    
        
        # get all the actions from the tfplan json and loop through them, if any of them are not no-op then we have drift
        actions=$( jq -r '.resource_changes[].change.actions' /tmp/$environment/json/tfplan.json) 
        echo $actions
        for action in $( echo $actions | jq -r '.[]'); do
            if [[ "$action" == "no-op" ]]; then
                echo $action
                echo "No changes for module: $module"
            else
                #DRIFT DETECTED
                echo $action
                echo "Changes detected for module: $module"
                echo "Resources with changes: $grab_json_body"
                echo "module_with_drift=$module" >> "${GITHUB_OUTPUT}"
                return 1
            fi
        done
    else
        echo "Module $module does not exist in environment. Skipping validation."
    fi
done
}

# locates the modules that has been changed in the lower environment
# this is to check if there is any drift for the changed modules
# has a condition to chec wether a marge has been done, as if so checking between branches will fail.
modules_changed=""
echo "Run CD checks: $run_cd_checks"
if [[ "$run_cd_checks" == "true" ]]; then
    echo "This is a merged pull request"
    commit_before_merge=$(git rev-parse HEAD^1)
    echo "Commit before merge: $commit_before_merge"
    modules_changed=$(terragrunt find --filter "[$higher_branch ... $commit_before_merge]" --format json | jq .)

    # The script needs to go checkout the commit from before the merge and do a plan
    # if the checkout does not happen it wont detect wether a branch is new or not and will fail when it should pass
    git checkout $commit_before_merge

    if check_module_status "$modules_changed" "$testing_environment"; then
        echo "No drift detected on $higher_branch for environment: $testing_environment"
        exit 0
    else
        echo "::error ::Drift detected on $higher_branch for environment: $testing_environment"
        exit 1
    fi
else
    git checkout $branch

    echo "This is not a merged pull request"
    modules_changed=$(terragrunt find --filter "[$higher_branch ... $branch]" --format json | jq .)

    ## check if modules are changing in the lower environment, if not then we can skip the drift detection as there is no change to the infrastructure
    if check_module_status "$modules_changed" "$testing_environment"; then
        echo "No changes detected in the lower environment. Skipping drift detection."
        exit 0
    else
        echo "Changes detected in the lower environment. Checking for drift in higher environment."

        echo "Modules changed: $modules_changed"

        git checkout $higher_branch

        echo "Checking drift for modules: $modules_changed"

        terragrunt run --all init

        if check_module_status "$modules_changed" "$testing_environment"; then
            echo "No drift detected on $higher_branch for environment: $testing_environment"
            exit 0
        else
            echo "::error ::Drift detected on $higher_branch for environment: $testing_environment"
            exit 1
        fi
    fi
fi