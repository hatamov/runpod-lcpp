#!/bin/bash
ls ./.restart_trigger | entr -r -n ./update-and-start.sh
