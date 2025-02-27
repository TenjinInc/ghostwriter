# Release Notes

## 1.4.0 (2023-09-13)

### Major

* none

### Minor

* Support for graceful handling of nested tables
* Increased minimum ruby to 3.3

### Bugfixes

* none

## 1.3.0 (2023-09-13)

### Major

* none

### Minor

* Increased minimum Ruby to 3.1

### Bugfixes

* none

## 1.2.1 (2021-10-29)

### Major

* none

### Minor

* Updated Nokogiri version to resolve https://github.com/advisories/GHSA-7rrm-v45f-jp64
* Updated Ruby version dependency to match
* Relaxed dependency upper bounds

### Bugfixes

* none

## 1.1.0 (2021-03-23)

### Major

* none

### Minor

* Added customization for headings
* Headings now marked more for higher order headings
* Added customization for list markers
* Added customization for table markers
* Writer is now immutable

### Bugfixes

* none

## 1.0.1 (2021-03-22)

### Major

* none

### Minor

* Updated README

### Bugfixes

* Fixed hr padding behaviour

## 1.0.0 (2021-03-21)

### Major

* Moved `link_base` parameter to constructor
* Moved input HTML parameter to `#textify`

### Minor

* Treats tables and lists with role="presentation" as simple containers
* Now handles ordered and unordered lists
* Images are now replaced with their alt text

### Bugfixes

* none

## 0.4.2 (2021-03-17)

### Major

* none

### Minor

* none

### Bugfixes

* Works with links using `tel:` and `mailto:` schemas.

## 0.4.1 (2021-03-17)

### Major

* none

### Minor

* No longer provides link target in brackets after link text when they are the same

### Bugfixes

* Added explicit testing for HTML entity interpretation

## 0.4.0 (2021-03-16)

### Major

* Updated gem dependencies

### Minor

* Updated docs
* Added support for tables

### Bugfixes

* none

## 0.3.0 (2016-03-06)

### Major

* Renamed to Ghostwriter

### Minor

* Docs: Added instruction for using textify with mail gem

### Bugfixes

* none


