# Release Notes

## 1.2.0 (2021-10-28)

### Major

* none

### Minor

* Updated Nokogiri version to resolve https://github.com/advisories/GHSA-7rrm-v45f-jp64

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


