set -xe
# change this value to fit for the higher environment, e.g. prod, staging, dev

echo "Checking for drift on $higher_branch for environment: $environment"

check_module_status() {
local changes_modules_to_check="$1"
local environment="$2"
local failure=false
terragrunt run --all init
for module in $(echo "$modules_changed" | jq -r '.[].path' | grep "$environment" ); do
    echo "Checking module: $module for drift"
    if [[ -d "$module" && $(compgen -G "$module/*.hcl") ]]; then

        terragrunt run plan --working-dir "$module" -- -out="$tf_plan_file_route/tfplan.binary"
        terragrunt show -json $tf_plan_file_route/tfplan.binary > $tf_plan_json_route/tfplan.json

        grab_json_body=$(jq -r '.resource_changes[] | select(.change.actions | index("no-op") | not) | "\(.address) → actions: \(.change.actions | join(", "))" ' $tf_plan_json_route/tfplan.json)    
        
        # get all the actions from the tfplan json and loop through them, if any of them are not no-op then we have drift
        actions=$( jq -r '.resource_changes[].change.actions' $tf_plan_json_route/tfplan.json) 
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


## note for this function
## if there is drift detected  on the previous commit terraform trigger analysis on latest commmit
## if there is drift detection on the latest commit and previous it means that the code coming in the latest commit will not resolve the drift
## as such fail to prevent potential damage..
check_drift_for_environments(){
higher_environment="$1"
lower_env_to_checkout="$2"
higher_branch_to_check="$3"

git checkout $lower_env_to_checkout

echo "This is not a merged pull request"
modules_changed=$(terragrunt find --filter "[$higher_branch_to_check ... $lower_env_to_checkout]" --format json | jq .)

## check if modules are changing in the lower environment, if not then we can skip the drift detection as there is no change to the infrastructure
if check_module_status "$modules_changed" "$higher_environment"; then
    echo "No changes detected on PR base $lower_env_to_checkout, Skipping drift detection."
    exit 0
else
    echo "Changes detected on PR base $lower_env_to_checkout. Checking for drift in higher environment."

    git checkout $higher_branch_to_check

    echo "Checking drift for modules: $modules_changed"

    rm $tf_plan_json_route/*
    rm $tf_plan_file_route/*

    if check_module_status "$modules_changed" "$higher_environment"; then
        echo "No drift detected on $higher_branch_to_check for environment: $higher_environment"
        exit 0
    else
        echo "::error ::Drift detected on $higher_branch_to_check for environment: $higher_environment"
        exit 1
    fi
fi

}

# locates the modules that has been changed in the lower environment
# this is to check if there is any drift for the changed modules
# has a condition to chec wether a marge has been done, as if so checking between branches will fail.
modules_changed=""
echo "Run CD checks: $run_cd_checks"
mkdir -p $tf_plan_file_route
mkdir -p $tf_plan_json_route
if [[ "$run_cd_checks" == "true" ]]; then
    echo "This is a merged pull request"
    commit_before_merge=$(git rev-parse HEAD^1)
    echo "Commit before merge: $commit_before_merge"
    check_drift_for_environments "$testing_environment" "$commit_before_merge" "$higher_branch"
else
    echo "This is not a merged pull request, checking for drift between branches"
    check_drift_for_environments "$testing_environment" "$branch" "$higher_branch"
fi