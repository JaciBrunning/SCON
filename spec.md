# SCON Specifications

SCON -- Simple and Compressed Object Notation

## Key Logic
  Keys in Hash objects are often repeated among multiple entries, so in the interest
  of compression, we assign a 'lookup' to each key. If a key is used more than once
  in the entire dataset (and children), a lookup value will be assigned in form of a
  number. Key Lookups are defined in a 'header' portion of the file, and the 'index'
  of the lookup will be used as the lookup value later in the file, used in place of
  the regular string key.

## Data Types
| Data Type | Hex Instruction | Data Space  |
|-----------|-----------------|------------:|
| Byte      | 0xA0            | 1 Byte      |
| Short     | 0xA1            | 2 Byte      |
| Integer   | 0xA2            | 4 Byte      |
| Long      | 0xA3            | 8 Byte      |
| Float     | 0xA4            | 4 Byte      |
| Double    | 0xA5            | 8 Byte      |
| NIL       | 0xC0            | -           |
| TRUE      | 0xC1            | -           |
| FALSE     | 0xC2            | -           |
| String    | 0xD0            | Variable    |
| Hash Start| 0xFA            | -           |
| Hash End  | 0xFB            | -           |
| Array Start| 0xFC           | -           |
| Array End | 0xFD            | -           |

  Some Data Types are special, in that they are handled differently depending on
a number of factors.
  - Byte -- Can be notated as 0x00 - 0x99 in a entry definition to save space
  - NIL / TRUE / FALSE -- Enumerations, instruction contains value instead of data
  - Hash/Array Start/End -- Control Switches
  - String -- If the length of the string is less than 32 bytes, a range of 0xD0 - 0xEF is used. Else,
0x03 (end-of-text) is used to define the end of the string.

*These exceptions are defined in more detail later in the document*

## Data Format

### Entry Encoding
  Each Data Type has it's own type of encoding to follow. In most cases, a little-endian byte
  representation is used, but there are a few exceptions when it comes to data layout.


  Most entries follow this pattern:  
&nbsp;    ```[data_type] [data_index] [data]```  
&nbsp;  &nbsp;  Where:  
 &nbsp;  &nbsp;  ```[data_type]``` is the byte representation of the Data Type as defined in the table  
 &nbsp;  &nbsp;  ```[data_index]``` is the lookup / string representation of the 'key' of the entry. This is not included for Arrays, as Array indexes are considered auto-incrementing  
 &nbsp;  &nbsp;  ```[data]``` is the encoded value of the entry. This is empty for some data types and conditions.  

#### Special Cases
  - **String**
    - **Less than 32 bytes**:
      - ```[data_type]```: ```0xD0``` + String Length. This results in a range of 0xD0 - 0xEF, which is reserved for String Lengths, requiring no 'data-termination' flag.
      - ```[data]```: The bytes of the string
    - **More than 32 bytes**:
      - ```[data_type]```: ```0xD0```
      - ```[data]```: The bytes of the string, appended with ```0x03``` (end-of-text) to signify a termination of String Data.  
  - **Numbers**
      - Numbers are automatically registered a type depending on the value of the number, in order to save space. *(Whole Numbers only)*
      - **Less than ```0x99```**
        - ```[data_type]```: The number value. Starting from ```0xA0``` is reserved for types, so ```0x00 - 0x99``` is reserved for implicit definition of numbers
        - ```[data]```: No Value
      - **Less than ```(2^16 / 2 - 1)```**
        - ```[data_type]```: Short (```0xA1```)
        - ```[data]```: A 2-Byte representation of the number
      - **Less than ```(2^32 / 2 - 1)```**
        - ```[data_type]```: Integer (```0xA2```)
        - ```[data]```: A 4-Byte representation of the number
      - **Less than ```(2^64 / 2 - 1)```**
        - ```[data_type]```: Long (```0xA3```)
        - ```[data]```: An 8-Byte representation of the number
  - **Nil / True / False**
    - Nil, True and False are defined as enumeration values. This means their data type is their value.
    - ```[data_type]```: ```0xC0 - 0xC2``` as defined in the table
    - ```[data]```: No Value
  - **Hash / Arrays**
    - Hashes and Arrays are treated as nested objects, where a ```0xFA/FC``` byte denotes the start of a new Hash or Array, and their ```0xFB/FD``` counterpart denotes the closing of one. This is not done for the root object.
    - ```0xFA/FC``` should be followed by a standard ```[data_index]``` if they are enclosed in a Hash. e.g. ```0xFA [data_index] <data as normal> 0xFB```


#### Data Index
  For Hash Types, the Data Index can follow multiple formats.
  - **Key has Lookup Value**
    - ```[data_index]```: A Number Representation of the index in the lookup header. Number
    auto-type assignment is used as defined in Special Cases. e.g. ```[data_index] = [data_type] [data]```
  - **Key does not have Lookup Value**
    - ```[data_index]```: If the key does not have a lookup value (only occurs once), a string is used instead. The string format is the same as defined in Special Cases.  

Arrays do not have a Data Index as they are treated as each entry is consecutive in the array (auto-increment)

### Data Encoding

  There are 2 data models a SCON file can follow: Hash and Array.  
  Hash types associate each value to a key, while Arrays are simply a collection of
  data in a 'list'.

### Hash
  Hash Files first begin the key lookup defined in the Key Logic section. If any key Lookups
are to be made, the first byte written to the datastream will be ```0xF1```, to denote that a key lookup is being used. Following are string representations of each key in the lookup.  
  After all the keys have been added to the header, a ```0xF0``` byte is written to denote that a Hash is
being used as the root object. After this, data can be written as normal as defined by the Entry Encoding.

**Example Representation:**
```
{% if lookup used
  0xF1
  - write each key lookup -
%}
0xF0
- data as normal -
```

### Array
  Array Files use a key lookup if the array contains any Hash Values that have recurring keys. This is the
same as hash files, where the first byte will be ```0xF1``` if a lookup is used, followed by the string representations of each key in the lookup. After this, the data is simply written as normal as defined by the Entry Encoding. Indexes are not used as consecutive values are considered to be consecutive in the Array order.

**Example Representation:**
```
{% if lookup used
  0xF1
  - write each key lookup -
%}
- data as normal -
```
