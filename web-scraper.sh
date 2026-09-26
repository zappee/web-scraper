#!/bin/bash -eu
# ##############################################################################
# Name:        Web Scraper
# Description: Crawls a website, follows its internal links, and converts all
#              discovered pages into clean, structured text for AI consumption.
#
# Usage:       web-scraper.sh <url> <output-file>
#              • url:         The base URL of the website to crawl
#              • output-file: The text file destination for the extracted content
#
# Example:     web-scraper.sh https://zappee.github.io zappee.github.io.txt
#
# Author:      Arnold Somogyi <arnold.somogyi@gmail.com>
# Release:     February 2024
# ##############################################################################

SITE="$1"
OUTPUT_FILE="$2"

# pipe-separated list of file extensions to exclude from crawling
CONTENT_TO_IGNORE="png|jpg|jpeg|gif|ico|svg|pdf|zip|gz|js|css|xml|webp|woff2"

# ANSI escape codes for terminal text formatting
ERROR_MESSAGE_STYLE="\033[38;5;196;48;5;16m"
DEFAULT_TEXT_COLOR="\033[0m"

# ----------------------------------------------------------------------------
# Show the manual.
# ------------------------------------------------------------------------------
function show_manual() {
  printf "%s\n" "Name:        sitecopy"
  printf "%s\n" "             Crawls a website, follows its internal links, and converts all"
  printf "%s\n" "             discovered pages into clean, structured text for AI consumption."
  printf "\n"
  printf "%s\n" "Usage:       sitecopy.sh <url> <output-file>"
  printf "%s\n" "                <url>: The base URL of the website to crawl"
  printf "%s\n" "                <output-file>: The text file destination for the extracted content"
  printf "\n"
  printf "%s\n" "Example:     ./sitecopy.sh https://zappee.github.io zappee.github.io.txt"
  printf "\n"
  printf "%s\n" "Author:      Arnold Somogyi <arnold.somogyi@gmail.com>"
  printf "%s\n" "Release:     February 2024"
  printf "%s\n" "Copyright (c) 2020-2026 Remal Software and Arnold Somogyi. All rights reserved."
}

# ----------------------------------------------------------------------------
# Validate user input.
#
#    param-1: first command line parameter
#    param-2: second command line parameter
# ------------------------------------------------------------------------------
function validate_user_input() {
  if (( $# < 2 )) || [[ -z "$1" || -z "$2" ]]; then
    printf "%b%s%b\n" "${ERROR_MESSAGE_STYLE}" "Illegal number of parameters." "${DEFAULT_TEXT_COLOR}"
    show_manual
    exit 1
  fi
}

# ------------------------------------------------------------------------------
# Check if the command exists.
#
#    param-1: the command to check
# ------------------------------------------------------------------------------
function check_command() {
  local _cmd="$1"

  if ! command -v "$_cmd" &> /dev/null; then
    printf "%b%s%b\n"  "${ERROR_MESSAGE_STYLE}" "Error: '$_cmd' is not installed." "${DEFAULT_TEXT_COLOR}"
    echo "Run: sudo apt install $_cmd"
    return 1
  fi
  return 0
}

# ------------------------------------------------------------------------------
# Get internal links from a url represents a web page.
#
#    param-1: url
#    param-2: return parameter for the links
# ------------------------------------------------------------------------------
function get_links() {
  local _url="$1"
  local _max_depth=2 # 1 = main page only, 2 = main page + its subpages, 3 = next level, etc.
  declare -n _links="$2"

  local _domain
  _domain="${_url#*//}"
  _domain="${_domain%%/*}"

  debug "domain name: ${_domain}"
  debug "🔍 getting external links from ${_url}..."

  readarray -t _links < <(
    # run the crawler pipeline
    wget \
        --spider \
        --recursive \
        --level="$_max_depth" \
        --no-verbose \
        --directory-prefix "$TMP_DIR" \
        --connect-timeout=10 \
        --timeout=120 \
        --domains "$_domain" \
        --tries=2 \
        --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
        --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" \
        --header="Accept-Language: en-US,en;q=0.5" \
        "$_url" 2>&1 |
      grep -oE "https?://[a-zA-Z0-9./?=&_-]+" |
      grep -vE "\.($CONTENT_TO_IGNORE)(\?.*)?$" | # filter assets and handle URL query params like ?id=123
      sort -u
  )

  for _link in "${_links[@]}"; do
    debug "  * $_link"
  done
}

# ------------------------------------------------------------------------------
# Download the content from the url and convert it to text.
#
#    param-1: url, e.g. https://zappee.github.io
#    param-2: list of the links
#    param-3: return parameter for the text content
# ------------------------------------------------------------------------------
function get_url_as_text() {
  declare -n _links="$2"
  declare -n _content_as_text="$3"

  for _link in "${_links[@]}"; do
    debug "🔄 converting ${_link} to text..."

    # download and convert html content to text
    local separator
    separator="------------------------------------------------------------------------------------"

    local _header
    printf -v _header "%s\n%s %s\n%s" "$separator" "SOURCE:" "${_link}" "$separator"

    local _text_content
    _text_content=$(curl -s "${_link}" | pandoc -f html -t plain)

    local _combined
    printf -v _combined "%s\n%s\n" "$_header" "$_text_content"

    # add to array
    _content_as_text+=("$_combined")
  done
}

# ------------------------------------------------------------------------------
# Save array to text file.
#
#    param-1: name of the textfile
#    param-2: an array with text content to save
# ------------------------------------------------------------------------------
function save() {
  local _output_file="$1"
  declare -n _content_array="$2"

  if [ -f "$_output_file" ]; then
    debug "🗑️ existing file deleted: ${_output_file}"
    rm "$_output_file"
  fi

  debug "💾 saving text content to ${_output_file}"
  for _content in "${_content_array[@]}"; do
    printf "%s\n" "$_content"
  done > "$_output_file"
}

# ------------------------------------------------------------------------------
# General logger.
#
#    param-1: log message
# ------------------------------------------------------------------------------
function debug() {
  local message="$1"
  printf "%s | %s%s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "$message"
}

# ------------------------------------------------------------------------------
# Even in 'wget  --spider' mode, recursive crawling forces wget to map out the
# structure of the site locally to keep track of where it has been. By default,
# it builds this structure in your current working directory. Adding -P /tmp
# forces wget to build that temporary in a specific place.
#
# We create a unique temporary directory inside the current working directory
# and ensure it gets deleted automatically when the script exits or finishes.
# ------------------------------------------------------------------------------
function init_workspace() {
  TMP_DIR=$(mktemp -d -p .)
  trap 'rm -rf "$TMP_DIR"' EXIT
  debug "Temp directory created, will auto-delete on exit: ${TMP_DIR}"
}

# ------------------------------------------------------------------------------
# Main program starts.
# ------------------------------------------------------------------------------
check_command wget
check_command lynx
check_command curl
check_command pandoc

init_workspace
validate_user_input "$SITE" "$OUTPUT_FILE"
get_links "$SITE" "LINKS"
get_url_as_text "$SITE" "LINKS" "CONTENT_AS_TEXT"
save "$OUTPUT_FILE" "CONTENT_AS_TEXT"
