## 🐧 Web-Scraper for AI


### 1) Overview
This web scraper is a software tool designed to extract textual data from websites and convert it into structured text content.
This clean data can then be used to feed AI models and ask questions about the content.

You need a web scraper because AI models cannot directly read a website URL and usually do not have internet access.
Instead, they require raw text or structured data to process information.
While humans see visual layouts, images, and buttons in a browser, an AI needs clean text stripped of code and styling to understand and analyze it.


### 2) The main reasons you need a scraper

1. **Cleaning the noise**

   Webpages are filled with style definitions, code, images, scripts, navigation bars, etc.
   If you pass a raw webpage to an AI, you will waste valuable tokens trying to read code instead of your content.
   A scraper extracts only the relevant text, such as a blog body, product description, or article text.

2. **AI prompt size limits**

   AI models operate within a context window (the maximum amount of text they can process at once).
   Without a scraper, a single webpage's source code can be massive, easily exhausting the AI's limit.
   A scraper compresses the content into pure text, allowing you to feed the AI significantly more information at a lower cost.

3. **Handling multipage sites**

   If your website has dozens of pages, manually copying and pasting every link is inefficient.
   A scraper can act as a crawler, automatically following internal links and gather all the text into a single file for instant AI processing.


### 3) How to use
The _Remal Web Scraper for AI_ is a Linux tool written in Bash.
Getting started is simple: just copy the script to your machine, grant execution permissions, and run it.

```
# grant execution permissions
$ chmod +x remal_scraper.sh

run the script
$ ./remal_scraper.sh <url> <output-file>

# example
$ ./web-scraper.sh https://zappee.github.io zappee.github.io.txt
```

### 🤝 Contributing

Contributions, feature requests, optimization, and bug reports are always welcome!
For more information, please visit my [homepage](https://zappee.github.io).
