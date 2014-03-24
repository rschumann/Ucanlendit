#!/bin/bash

echo "Running script"
echo "SUITE: ${SUITE}"

if [ "$SUITE" = "rspec" ]
then
	bundle exec rake spec 2>&1
	exit
elif [ "$SUITE" = "cucumber" ]
then
	PHANTOMJS=true NO_WEBDRIVER_MONKEY_PATCH=true bundle exec cucumber -ptravis 2>&1
	exit
elif [ "$SUITE" = "mocha" ]
then
	grunt connect mocha 2>&1
	exit
elif [ "$SUITE" = "jshint" ]
then
	grunt jshint 2>&1
	exit
else
	echo -e "Error: SUITE is illegal or not set\n"
	exit 1
fi