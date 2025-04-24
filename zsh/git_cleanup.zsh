# Function to conditionally print verbose messages in yellow
# Usage: echo_verbose "true" "[Verbose] Some message"
echo_verbose() {
  local verbose="$1"
  local message="$2"
  [[ "$verbose" == "true" ]] && echo_yellow "[Verbose] $message"
}

echo_yellow() {
  echo -e "\e[33m$1\e[0m"
}

echo_green() {
  echo -e "\e[32m$1\e[0m"
}

echo_blue() { 
  echo -e "\e[34m$1\e[0m"
}

echo_red() {
  echo -e "\e[31m$1\e[0m"
}

echo_default() {
  echo -e "\e[39m$1\e[0m"
}

prompt_red() {
  echo -n "\e[31m$1\e[0m"
}


fetch_and_prune() {
  local verbose="$1"
  echo_verbose "$verbose" "Fetching and pruning remote branches..."
  git fetch --prune
}

get_branches_to_delete() {
  git branch -vv | grep ': gone]' | awk '{print $1}'
}

prompt_and_delete_branch() {
  local branch="$1"
  local verbose="$2"
  local deleted_branches_var="$3"
  local skipped_branches_var="$4"
  echo_verbose "$verbose" "Processing branch: $branch"
  prompt_red "Delete branch '$branch'? [y/N] "
  read response
  if [[ "$response" == "y" || "$response" == "Y" ]]; then

    echo_verbose "$verbose" "Attempting to delete: $branch"
    if ! git branch -d "$branch"; then
      echo_verbose "$verbose" "Soft delete failed for $branch, asking for force deletion"
      prompt_red "Branch '$branch' is not fully merged. Force delete? [D/n] "
      read force_response
      if [[ "$force_response" == "D" ]]; then
        echo_verbose "$verbose" "Force deleting: $branch"
        git branch -D "$branch"
        eval "$deleted_branches_var+=(\"$branch\")"
      else
        echo "Skipping $branch"
        eval "$skipped_branches_var+=(\"$branch\")"
      fi
    else
      eval "$deleted_branches_var+=(\"$branch\")"
    fi
  else
    echo "Skipping $branch"
    eval "$skipped_branches_var+=(\"$branch\")"
  fi
}

cleanup_git_branches() {
  local force=false
  local verbose=false
  local deleted_branches=()
  local skipped_branches=()

  for arg in "$@"; do
    case "$arg" in
      -d|--dry-run)
        echo "Branches that would be deleted:"
        while read -r branch; do
          echo "$branch"
        done < <(get_branches_to_delete)
        echo "Remote branches that would be pruned:"
        git remote prune origin --dry-run
        return
        ;;
      -f|--force)
        force=true
        ;;
      -v|--verbose)
        verbose=true
        ;;
    esac
  done

  fetch_and_prune "$verbose"
  local branches_to_delete
  branches_to_delete=($(get_branches_to_delete))

  if [[ ${#branches_to_delete[@]} -eq 0 ]]; then
    echo_blue "No local branches to delete."
    return
  fi

  echo_green "${#branches_to_delete[@]} branches will be processed for deletion.\n"

  if [[ "$force" == "true" ]]; then
    echo "Force deleting branches:"
    for branch in "${branches_to_delete[@]}"; do
      echo_verbose "$verbose" "Force deleting: $branch"
      git branch -D "$branch"
      deleted_branches+=("$branch")
    done
  else
    for branch in "${branches_to_delete[@]}"; do
      prompt_and_delete_branch "$branch" "$verbose" deleted_branches skipped_branches
    done
  fi

  echo_blue "\nSummary:"
  echo_blue "Deleted branches: ${#deleted_branches[@]}"
  echo_blue "Skipped branches: ${#skipped_branches[@]}"
  
  if [[ "$verbose" == "true" ]]; then
    if [[ ${#deleted_branches[@]} -gt 0 ]]; then
      echo_verbose "$verbose" "Deleted:"
      printf '%s\n' "${deleted_branches[@]}"
    else
      echo_verbose "$verbose" "No branches deleted."
    fi
    
    if [[ ${#skipped_branches[@]} -gt 0 ]]; then
      echo_verbose "$verbose" "Skipped:"
      printf '%s\n' "${skipped_branches[@]}"
    else
      echo_verbose "$verbose" "No branches skipped."
    fi
  fi
}

