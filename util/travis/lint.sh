#! /bin/bash
function perform_lint() {
        echo "Performing LINT..."
        CLANG_FORMAT=clang-format
        CLANG_FORMAT_WHITELIST="util/travis/clang-format-whitelist.txt"

        if [ "$TRAVIS_EVENT_TYPE" = "pull_request" ]; then
                # Get list of every file modified in this pull request
                files_to_lint="$(git diff --name-only --diff-filter=ACMRTUXB $TRAVIS_COMMIT_RANGE | grep '^src/[^.]*[.]\(cpp\|h\)$' | true)"
        else
                # Check everything for branch pushes
                files_to_lint="$(find src/ -name '*.cpp' -or -name '*.h')"
        fi

        local errorcount=0
        local fail=0
        for f in ${files_to_lint}; do
                d=$(diff -u "$f" <(${CLANG_FORMAT} "$f") || true)

                if ! [ -z "$d" ]; then
                        whitelisted=$(egrep -c "^${f}" "${CLANG_FORMAT_WHITELIST}")

                        # If file is not whitelisted, mark a failure
                        if [ ${whitelisted} -eq 0 ]; then
                                errorcount=$((errorcount+1))

                                printf "The file %s is not compliant with the coding style" "$f"
                                if [ ${errorcount} -gt 50 ]; then
                                        printf "\nToo many errors encountered previously, this diff is hidden.\n"
                                else
                                        printf ":\n%s\n" "$d"
                                fi

                                fail=1
                        fi
                fi
        done

        if [ "$fail" = 1 ]; then
                echo "LINT reports failure."
                exit 1
        fi

        echo "LINT OK"
}

