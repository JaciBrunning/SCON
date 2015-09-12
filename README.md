# SCON

Simple and Compressed Object Notation

## Getting Started

Getting started with SCON is very simple. First, install the Gem:
```
gem install scon
```
or, in your gem file:
```ruby
gem 'scon'
```  

Using the Gem is very simple. To generate SCON from a Hash or Array, simply do the following:
```ruby
require 'scon'
hash = {:test => true, :greeting => "Hello World"}
scon_string = SCON.generate!(hash)
```
Parsing is just as simple:
```ruby
require 'scon'
puts SCON.parse!(scon_string)
```

## What is this?
SCON is an Object Notation format following the premise of being really small. Similar to JSON and MessagePack formats, SCON serializes Arrays and Hashes (objects) into a single byte-stream or String,
for easy information interchange.  

SCON serialized objects are really small thanks to some clever type definitions and detection of duplicate
keys. Let's take a look.

The below JSON sample shows something you would expect from a REST API or other file.
```json
{
  "data": [
    {
      "id": 0,
      "name": "My Name",
      "type": "My Type",
      "value": 0.536,
      "acceptable": true
    },
    {
      "id": 1,
      "name": "My Other Name",
      "type": "My Other Type",
      "value": -0.2545,
      "acceptable": false
    },
    { ... }
  ]
}
```
As you can see, there are a lot of keys that are duplicated for each entry, ```id```, ```name```,
```type```, ```value``` and ```acceptable```. As more and more entries are added, these key names
just take up more and more space, making the file larger than it needs to be.  

SCON stores keys that occur more than once in a 'header' section of the file. Each of these keys is linked
to an integer ID, where all future occurrences of this key will be replaced, making the system much more
efficient. This Lookup Table is responsible for a lot of saved bytes on particularly large files such as REST API listings or Save Game files.  

Some Byte Trickery is also used to decrease the file size. The most notable of which, is the auto-number system. In short, numbers that are lower than the maximum value of one byte are stored in a single byte, however larger numbers are stored as shorts, integers and longs respectively. Bytes ```0x00 - 0x99``` are also implicit, meaning they only take up one byte for both the type declaration and the value. ```0xA0 - 0xFF``` are reserved for control codes and types.  

NIL, TRUE and FALSE also use only one byte for the type declaration and value, ```0xC0```, ```0xC1``` and ```0xC2``` respectively. More information regarding the storage system can be found in the Format Specification.

## Example Results
Following are some simple examples of SCON, facing off against JSON (non-pretty-print), CBOR and MessagePack *(All values in Bytes)*  

### Test 1:
```ruby
{ :compact => true, :schema => 0 }
```

| JSON | MsgPack | CBOR | SCON |
|-----:|--------:|-----:|-----:|
|27|**18**|**18**|**18**|

### Test 2:
```ruby
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
```

| JSON | MsgPack | CBOR | SCON |
|-----:|--------:|-----:|-----:|
|21|11|11|**10**|

### Test 3:
```ruby
  {
    :test => {
      :test => true,
      :data => "Hello World"
    },
    :array => [1, 2, 3],
    :test2 => {
      :test => false,
      :array => [
        { :data => "Hello" }, "World"
      ],
      :data => 2.3
    }
  }
```

| JSON | MsgPack | CBOR | SCON |
|-----:|--------:|-----:|-----:|
|128|92|92|**76**|

### Test 4:
```ruby
(0..10000).map { |x|
  { :id => x,
    :name => "My Name",
    :boolean => true,
    :test_long_key_name => -258.52325 }}
```

| JSON | MsgPack | CBOR | SCON |
|-----:|--------:|-----:|-----:|
|758 968|569 676|569 780|**229 751**|

### Test 5:
```ruby
[0, Array.new(100).fill(nil), 100]  # 100 Blank Indexes
```

| JSON | MsgPack | CBOR | SCON |
|-----:|--------:|-----:|-----:|
|509|106|106|**104**|
