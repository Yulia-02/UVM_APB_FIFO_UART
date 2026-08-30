# ============================================
# UVM Regression + Coverage Script
# ============================================

# ------------------------------------------------
# Coverage output directory
# ------------------------------------------------
set covdir "./coverage_results"

# Create directory if it does not exist
if {![file exists $covdir]} {
    file mkdir $covdir
}

# ------------------------------------------------
# Clean OLD coverage results BEFORE regression
# ------------------------------------------------
foreach f [glob -nocomplain "$covdir/*.ucdb"] {
    file delete -force $f
}

foreach f [glob -nocomplain "$covdir/*.txt"] {
    file delete -force $f
}


# ------------------------------------------------
# Test list
# ------------------------------------------------
set tests {
    write_test
    multi_write_test
    data_pattern_test
    full_test
    empty_test
    status_read_test
    invalid_addr_test
    depth_config_test
    reset_test
    rpt_wrap_test
    baud_div_zero_test
}


# ------------------------------------------------
# Run regression
# ------------------------------------------------
foreach test $tests {

    echo ""
    echo "========================================"
    echo "Running $test"
    echo "========================================"

    vsim -coverage tb_top +UVM_TESTNAME=$test

    run -all

    # Save functional + code coverage for this test
    coverage save "$covdir/${test}.ucdb"

    quit -sim -f
}


echo ""
echo "========================================"
echo "Regression completed"
echo "========================================"


# ------------------------------------------------
# Merge all UCDB files
# ------------------------------------------------
exec vcover merge "$covdir/merged.ucdb" \
    "$covdir/write_test.ucdb" \
    "$covdir/multi_write_test.ucdb" \
    "$covdir/data_pattern_test.ucdb" \
    "$covdir/full_test.ucdb" \
    "$covdir/empty_test.ucdb" \
    "$covdir/status_read_test.ucdb" \
    "$covdir/invalid_addr_test.ucdb" \
    "$covdir/depth_config_test.ucdb" \
    "$covdir/reset_test.ucdb"\
    "$covdir/rpt_wrap_test.ucdb"\
    "$covdir/baud_div_zero_test.ucdb"



# ------------------------------------------------
# Functional coverage report
# ------------------------------------------------
exec vcover report \
    -details \
    -cvg \
    -output "$covdir/functional_coverage_report.txt" \
    "$covdir/merged.ucdb"


# ------------------------------------------------
# Overall / Code coverage report
# ------------------------------------------------
exec vcover report \
    -details \
    -output "$covdir/code_coverage_report.txt" \
    "$covdir/merged.ucdb"


echo ""
echo "========================================"
echo "Coverage merge completed"
echo "Merged UCDB:"
echo "$covdir/merged.ucdb"
echo ""
echo "Functional coverage report:"
echo "$covdir/functional_coverage_report.txt"
echo ""
echo "Code coverage report:"
echo "$covdir/code_coverage_report.txt"
echo "========================================"