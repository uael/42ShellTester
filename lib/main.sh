#!/bin/sh

# /*
# Main function
#
# run_main
# function that:
# - iterates over the spec folder
# - executes the tests and their callbacks
# - displays the results
# */

function run_main
{
  local TEST
  local TEST_NAME
  local TEST_FULLNAME
  local RESULT
  local RESPONSE_STDOUT
  local RESPONSE_STDERR
  local EXIT_STATUS
  local RESPONSE_REFERENCE_STDOUT
  local RESPONSE_REFERENCE_STDERR
  local REFERENCE_EXIT_STATUS
  local RUN_TEST
  local RUN_ASSERT
  local TEST_STATUS
  local ASSERT_STATUS
  local LOG_CURRENT_TEST
  local LOG_CURRENT_TEST_STDOUT
  local LOG_CURRENT_TEST_STDERR
  local LOG_CURRENT_TEST_MISC
  local LOG_SUCCESS_TESTS
  local LOG_FAILED_TESTS
  local OLD_IFS="${IFS}"

  if [ ! -f "${GLOBAL_PROG}" ]
  then
    [ "${GLOBAL_PROG}" == "" ] && printf "%s\n" "Missing argument: specify the binary to test" && return
    [ ! -f "$(which "${GLOBAL_PROG}")" ] && printf "%s\n" "Wrong argument: the specified argument is not executable" && return
  fi

  IFS=$'\n'
  for TEST in $(find -E "${GLOBAL_INSTALLDIR}/spec" -type d -regex "${GLOBAL_INSTALLDIR}/spec/.*${GLOBAL_SPECS_FILTER}.*")
  do
    if [ -f "${TEST}/stdin" ] && [ ! -f "${TEST}/non-posix" -o "${GLOBAL_RUN_POSIX_ONLY}" == "0" ] && [ ! -f "${TEST}/pending" -o "${GLOBAL_RUN_PENDING_TESTS}" == "1" ] && [ ! -f "${TEST}/hard" -o "${GLOBAL_RUN_HARD_TESTS}" == "1" ]
    then

      TEST_NAME="${TEST##*/}"
      TEST_FULLNAME="${TEST##*spec/}"
      RUN_TEST=0
      TEST_STATUS="0"
      LOG_CURRENT_TEST="${TEST_FULLNAME}"
      LOG_CURRENT_TEST_STDOUT=""
      LOG_CURRENT_TEST_STDERR=""
      LOG_CURRENT_TEST_MISC=""

      RESPONSE_STDOUT="${GLOBAL_TMP_DIRECTORY}/${TEST_FULLNAME//\//-}.stdout"
      RESPONSE_STDERR="${GLOBAL_TMP_DIRECTORY}/${TEST_FULLNAME//\//-}.stderr"
      RESPONSE_REFERENCE_STDOUT="${GLOBAL_TMP_DIRECTORY}/${TEST_FULLNAME//\//-}.ref.stdout"
      RESPONSE_REFERENCE_STDERR="${GLOBAL_TMP_DIRECTORY}/${TEST_FULLNAME//\//-}.ref.stderr"

      rm -f "${GLOBAL_TMP_DIRECTORY}/stdin"
      local INDEX=1
      local LINE
      local TOTAL=$(awk 'END {print NR+1}' "${TEST}/stdin")
      while [ "$INDEX" -le "$TOTAL" ]
      do
        LINE="$(awk -v INDEX="${INDEX}" 'NR == INDEX {gsub(/\|/, "\"|\""); gsub(/;/, "\";\""); gsub(/>/, "\">\""); gsub(/&/, "\"&\""); gsub(/</, "\"<\""); gsub(/-/, "\"-\""); print $0; exit}' "${TEST}/stdin")"
        eval echo "${LINE}" >>"${GLOBAL_TMP_DIRECTORY}/stdin"

        (( INDEX += 1 ))
      done

      (
        if [ -f "${TEST}/before_exec" ]
        then

          local INDEX=0
          local TOTAL=$(awk 'END {print NR+1}' "${TEST}/before_exec")
          while [ "$INDEX" -le "$TOTAL" ]
          do
            eval $(awk -v INDEX="${INDEX}" 'NR == INDEX {print $0; exit}' "${TEST}/before_exec")
            (( INDEX += 1 ))
          done

        fi

        eval "${GLOBAL_PROG}" < "${GLOBAL_TMP_DIRECTORY}/stdin" 1> "${RESPONSE_STDOUT}.raw" 2> "${RESPONSE_STDERR}.raw"
      )
      EXIT_STATUS=${?}

      awk '{gsub(/\033\[[0-9;]*m/, ""); print}' "${RESPONSE_STDOUT}.raw" > "${RESPONSE_STDOUT}"
      awk '{gsub(/\033\[[0-9;]*m/, ""); print}' "${RESPONSE_STDERR}.raw" > "${RESPONSE_STDERR}"

      if [ "${GLOBAL_PROG_REFERENCE}" != "" ]
      then
        (
          if [ -f "${TEST}/before_exec" ]
          then

            local INDEX=0
            local TOTAL=$(awk 'END {print NR+1}' "${TEST}/before_exec")
            while [ "$INDEX" -le "$TOTAL" ]
            do
              eval $(awk -v INDEX="${INDEX}" 'NR == INDEX {print $0; exit}' "${TEST}/before_exec")
              (( INDEX += 1 ))
            done

          fi

          eval "${GLOBAL_PROG_REFERENCE}" < "${GLOBAL_TMP_DIRECTORY}/stdin" 1> "${RESPONSE_REFERENCE_STDOUT}.raw" 2> "${RESPONSE_REFERENCE_STDERR}.raw"
        )
        REFERENCE_EXIT_STATUS=${?}

        awk '{gsub(/\033\[[0-9;]*m/, ""); print}' "${RESPONSE_REFERENCE_STDOUT}.raw" > "${RESPONSE_REFERENCE_STDOUT}"
        awk '{gsub(/\033\[[0-9;]*m/, ""); print}' "${RESPONSE_REFERENCE_STDERR}.raw" > "${RESPONSE_REFERENCE_STDERR}"
      fi

      if [ -f "${TEST}/stdout" ]
      then
        RUN_ASSERT="0"
        if [ "${GLOBAL_PROG_REFERENCE}" != "" ]
        then
          run_assert "REFERENCE_" "STDOUT" 1>- 2>-
          RUN_ASSERT="${?}"
        fi
        if [ "${RUN_ASSERT}" == "0" ]
        then
          LOG_CURRENT_TEST_STDOUT="$(run_assert "" "STDOUT")"
          ASSERT_STATUS="${?}"
          if [ "${ASSERT_STATUS}" != "0" ]
          then
            [ "${TEST_STATUS}" == "0" -o "${TEST_STATUS}" == "2" ] && TEST_STATUS="${ASSERT_STATUS}"
          fi
          RUN_TEST=1
        fi
      fi

      if [ -f "${TEST}/stderr" ]
      then
        RUN_ASSERT="0"
        if [ "${GLOBAL_PROG_REFERENCE}" != "" ]
        then
          run_assert "REFERENCE_" "STDERR" 1>- 2>-
          RUN_ASSERT="${?}"
        fi
        if [ "${RUN_ASSERT}" == "0" ]
        then
          LOG_CURRENT_TEST_STDERR="$(run_assert "" "STDERR")"
          ASSERT_STATUS="${?}"
          if [ "${ASSERT_STATUS}" != "0" ]
          then
            [ "${TEST_STATUS}" == "0" -o "${TEST_STATUS}" == "2" ] && TEST_STATUS="${ASSERT_STATUS}"
          fi
          RUN_TEST=1
        fi
      fi

      if [ -f "${TEST}/misc" ]
      then
        RUN_ASSERT="0"
        if [ "${GLOBAL_PROG_REFERENCE}" != "" ]
        then
          run_assert "REFERENCE_" "MISC" 1>- 2>-
          RUN_ASSERT="${?}"
        fi
        if [ "${RUN_ASSERT}" == "0" ]
        then
          LOG_CURRENT_TEST_MISC="$(run_assert "" "MISC")"
          ASSERT_STATUS="${?}"
          if [ "${ASSERT_STATUS}" != "0" ]
          then
            [ "${TEST_STATUS}" == "0" -o "${TEST_STATUS}" == "2" ] && TEST_STATUS="${ASSERT_STATUS}"
          fi
          RUN_TEST=1
        fi
      fi


      if [ "${RUN_TEST}" == "1" ]
      then
        (( GLOBAL_TOTAL_TESTS = GLOBAL_TOTAL_TESTS + 1 ))

        if [ "${TEST_STATUS}" != "0" -o "${GLOBAL_SHOW_SUCCESS}" == "1" ]
        then
          GLOBAL_LOG="$(printf "%s\n\n%s" "${GLOBAL_LOG}" "${LOG_CURRENT_TEST}")"
          case "${TEST_STATUS}" in
            0) GLOBAL_LOG="$(printf "%s ${C_GREEN}%s${C_CLEAR}" "${GLOBAL_LOG}" "(SUCCESS)")" ;;
            1) GLOBAL_LOG="$(printf "%s ${C_RED}%s${C_CLEAR}" "${GLOBAL_LOG}" "(FAILED)")" ;;
            2) GLOBAL_LOG="$(printf "%s ${C_YELLOW}%s${C_CLEAR}" "${GLOBAL_LOG}" "(WARNING)")" ;;
            255) GLOBAL_LOG="$(printf "%s ${C_RED}%s${C_CLEAR}" "${GLOBAL_LOG}" "(RUNTIME ERROR)")" ;;
          esac
          [ -f "${TEST}/description" ] && GLOBAL_LOG="$(printf "%s\n  %s" "${GLOBAL_LOG}" "$(cat "${TEST}/description")")"
          [ "${LOG_CURRENT_TEST_STDOUT}" != "" ] && GLOBAL_LOG="$(printf "%s\n%s" "${GLOBAL_LOG}" "${LOG_CURRENT_TEST_STDOUT}")"
          [ "${LOG_CURRENT_TEST_STDERR}" != "" ] && GLOBAL_LOG="$(printf "%s\n%s" "${GLOBAL_LOG}" "${LOG_CURRENT_TEST_STDERR}")"
          [ "${LOG_CURRENT_TEST_MISC}" != "" ] && GLOBAL_LOG="$(printf "%s\n%s" "${GLOBAL_LOG}" "${LOG_CURRENT_TEST_MISC}")"
          [ "${TEST_STATUS}" == "1" ] && (( GLOBAL_TOTAL_FAILED_TESTS = GLOBAL_TOTAL_FAILED_TESTS + 1 ))
        fi

        case "${TEST_STATUS}" in
          0) printf "${C_GREEN}√${C_CLEAR}" ;;
          1) printf "${C_RED}x${C_CLEAR}" ;;
          2) printf "${C_YELLOW}~${C_CLEAR}" ;;
          255) printf "${C_RED}!${C_CLEAR}" ;;
        esac
      fi

    fi
  done
  IFS="${OLD_IFS}"
}
