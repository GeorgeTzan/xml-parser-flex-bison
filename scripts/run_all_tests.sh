#!/bin/bash

cd "$(dirname "$0")/.." || exit 1

echo "============================================"
echo "   Android XML Parser - Test"
echo "   Georgios Tzanopoulos - 2846"
echo "============================================"
echo ""

if [ ! -f myParser ]; then
    echo "⚠️  myParser not found. Building..."
    cd src && make clean && make && cd ..
    echo ""
fi

echo "Running tests..."
echo ""

echo "✓ Valid XML (General):"
./myParser tests/test_valid.xml 2>&1 | grep -E "OK|ERROR" | tail -1

echo ""
echo "✓ Valid XML (PDF Example):"
./myParser tests/pdf_test.xml 2>&1 | grep -E "OK|ERROR" | tail -1

echo ""
echo "✗ Missing Mandatory Attribute (New):"
./myParser tests/test_missing_text.xml 2>&1 | grep "Missing" | head -1

echo ""
echo "✗ Duplicate ID (Q2a):"
./myParser tests/test_q2a_duplicate_id.xml 2>&1 | grep "Duplicate" | head -1

echo ""
echo "✗ Invalid Dimension (Q2b):"
./myParser tests/test_q2b_invalid_dimension.xml 2>&1 | grep "Invalid" | head -1

echo ""
echo "✗ Invalid Padding (Q2c):"
./myParser tests/test_q2c_zero_padding.xml 2>&1 | grep "padding" | head -1

echo ""
echo "✗ Invalid CheckedButton (Q2d):"
./myParser tests/test_q2d_invalid_checked.xml 2>&1 | grep "checkedButton" | head -1

echo ""
echo "✗ Invalid Progress (Q2e):"
./myParser tests/test_q2e_invalid_progress.xml 2>&1 | grep "progress" | head -1

echo ""
echo "✗ Wrong RadioButton Count (Q3):"
./myParser tests/test_q3_radio_count.xml 2>&1 | grep "expected" | head -1

echo ""
echo "============================================"
echo "   All tests executed!"

