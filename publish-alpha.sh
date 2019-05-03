#!/bin/bash

circleci config pack src > orb.yml
circleci orb publish orb.yml circleci/docker@dev:alpha
rm -rf orb.yml
