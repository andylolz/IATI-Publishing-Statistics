#!/bin/bash
echo "LOG: `date '+%Y-%m-%d %H:%M:%S'` - Starting Stats generation"
echo $GITOUT_DIR
if [ "$GITOUT_DIR" = "" ]; then
    GITOUT_DIR="outputs"
fi
if [ "$COMMIT_SKIP_FILE" = "" ]; then
    COMMIT_SKIP_FILE=$GITOUT_DIR/gitaggregate/activities.json
fi

# Make the all the gitout directories
echo "LOG: `date '+%Y-%m-%d %H:%M:%S'` - Making gitout directories"
mkdir -p $GITOUT_DIR/logs
mkdir -p $GITOUT_DIR/gitaggregate


cd helpers
# Update codelist mapping, codelists and schemas
echo "LOG: `date '+%Y-%m-%d %H:%M:%S'` - Update codelist mapping"
./get_codelist_mapping.sh
echo "LOG: `date '+%Y-%m-%d %H:%M:%S'` - Update codelists"
./get_codelists.sh
echo "LOG: `date '+%Y-%m-%d %H:%M:%S'` - Update schemas"
./get_schemas.sh
# Build a JSON file of metadata for each CKAN publisher, and for each dataset published.
# This is based on the data from the CKAN API
echo "LOG: `date '+%Y-%m-%d %H:%M:%S'` - Running ckan.py"
python ckan.py
cd ..
echo "LOG: `date '+%Y-%m-%d %H:%M:%S'` - Copying ckan.json"
cp helpers/ckan.json $GITOUT_DIR


# Clear output directory
echo "LOG: `date '+%Y-%m-%d %H:%M:%S'` - Clearing output directory"
rm -r out

# Loop over commits and run stats code
# Run the stats commands and save output to log files
echo "LOG: `date '+%Y-%m-%d %H:%M:%S'` - Calculating stats (loop)"
python calculate_stats.py loop > $GITOUT_DIR/logs/loop.log || exit 1
echo "LOG: `date '+%Y-%m-%d %H:%M:%S'` - Calculating stats (aggregate)"
python calculate_stats.py aggregate > $GITOUT_DIR/logs/aggregate.log || exit 1
echo "LOG: `date '+%Y-%m-%d %H:%M:%S'` - Calculating stats (invert)"
python calculate_stats.py invert > $GITOUT_DIR/logs/invert.log || exit 1
echo "LOG: `date '+%Y-%m-%d %H:%M:%S'` - Moving json files to output folder"
mv -v out/* $GITOUT_DIR

echo "LOG: `date '+%Y-%m-%d %H:%M:%S'` - Running gitaggregate.py"
python statsrunner/gitaggregate.py
echo "LOG: `date '+%Y-%m-%d %H:%M:%S'` - Running gitaggregate-publisher.py"
python statsrunner/gitaggregate-publisher.py
echo "LOG: `date '+%Y-%m-%d %H:%M:%S'` - Stats calculation complete"
