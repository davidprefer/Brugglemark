# Brugglemark
Brugglemark ("browser" + "smuggle" + "bookmarks") is a PowerShell script that abuses browser bookmark synchronization as a mechanism for sending and receiving data between systems.

Should be compatible with any Chromium browser, such as Chrome, Edge, Opera, Brave, or Vivaldi.

*__NOTE:__ This was my first time writing a PowerShell script and I am not sure I will have the time to maintain and update it. I am open to letting a reputable volunteer take over; message me on [LinkedIn](https://www.linkedin.com/in/davidprefer).*

## Table of Contents
- [About](#about)
- [Usage](#usage)
- [Parameters](#parameters)
- [Credits](#credits)

## About
Converts raw text (currently supports plaintext files only) into base64 strings that are saved as individual bookmarks using the "Bookmarks" file in a user's profile directory. The data can then be reconstructed from those same bookmarks once they have been synced to a remote system (which is usually instant).

Created by [David Prefer](https://www.linkedin.com/in/davidprefer) (pronounced Pree-fer) as a proof of concept for an academic research paper ("Bookmark Bruggling: Novel Data Exfiltration with Brugglemark"). The paper can be found at [sans.edu/cyber-research/](https://www.sans.edu/cyber-research/bookmark-bruggling-novel-data-exfiltration-with-brugglemark/) or [sans.org/white-papers/](https://www.sans.org/white-papers/bookmark-bruggling-novel-data-exfiltration-with-brugglemark/).

## Usage
### Write Data to Bookmarks
`brugglemark -bruggle -ProfilePath '%LocalAppData%\Google\Chrome\User Data\Default\' -Data 'input_secrets.txt' -Chars 8500`
        
Write 'input_secrets.txt' to bookmarks (close any browser sessions associated with the target profile before running Brugglemark).

**NOTE:** Specify the folder name to write to within Mobile bookmarks using **`-bmFolderName`** (default is "brugglemark," but if the folder already exists then an incrementing number will be appended to the name (e.g., brugglemark1, brugglemark2, etc.).

### Reconstruct Data from Bookmarks
`brugglemark -unbruggle -ProfilePath '%LocalAppData%\Google\Chrome\User Data\Default\' -Data 'output_secrets.txt'`
        
Retrieve data from bookmarks and write to 'output_secrets.txt'.

**NOTE:** Specify the folder name to read from within Mobile bookmarks with **`-bmFolderName`**.

## Parameters
### **`-sp`**
Suppress prompts to continue.

| Aliases: | None |
| :-- | :-- |
| **Default Value:** | **N/A** |

### **`-bruggle`**
Required to write raw text (specified via **`-Data`**) to bookmarks. Data is encoded in base64 when written. Use with **`-bmFolderName`** to specify which bookmark folder to write to.

To ensure success, close any browser sessions associated with the target profile before writing to bookmarks.

| Aliases: | None |
| :-- | :-- |
| **Default Value:** | **N/A** |

### **`-unbruggle`**
Required to read data from bookmarks (writes to the filename specified by **`-Data`**). Data is decoded from base64 when read. Use with **`-bmFolderName`** to specify which bookmark folder to read from.

| Aliases: | None |
| :-- | :-- |
| **Default Value:** | **N/A** |

### **`-ProfilePath`**
Required to specify a target profile. Find a profile's path by visiting the *about:version* URL in Chrome, Edge, Brave, and Vivaldi, or *opera:about* in Opera.

**NOTE 1:** Brugglemark will fail if the "Bookmarks" file does not exist. Ensure at least one bookmark has been saved by the target profile so that the file is created.

**NOTE 2:** Do not include the "Bookmarks" file in the path, as this is handled automatically (and may be optionally specified with **`-BookmarksFile`** if necessary).

| Aliases: | Profile, P |
| :-- | :-- |
| **Default Value:** | **None** |

### **`-BookmarksFile`**
Specifies the name of the "Bookmarks" file. This only needs to be set if the target browser has deviated from the "Bookmarks" filename used by Chromium-based browsers. 

**NOTE:** Brugglemark will fail if the "Bookmarks" file does not exist. Ensure at least one bookmark has been saved by the target profile so that the file is created.

| Aliases: | B, JSONFile, J |
| :-- | :-- |
| **Default Value:** | **Bookmarks** |

### **`-Data`**
When **`-bruggle`** is specified, this is the file with raw data to be base64 encoded and converted into bookmarks.

When **`-unbruggle`** is specified, this is the file where the data from bookmarks will be written after it is reassembled and decoded.

| Aliases: | D, Read, R, Write, W, File, F |
| :-- | :-- |
| **Default Value:** | **None** |

### **`-Chars`**
Sets the maximum number of characters to be stored in each bookmark's name field (don't use a comma in the value). Recommended values (based on June 2022 research) are provided below.

| Browser | Recommended Max Characters |
| --- | --- |
| Chrome: | 8,000 - 9,000 |
| Edge: | 32,500 |
| Brave: | 100,000 - 300,000 |
| Opera: | 100,000 - 3,000,000 |

| Aliases: | C |
| :-- | :-- |
| **Default Value:** | **8500** |

### **`-bmDate`**
Controls the value of the date_added field in each bookmark created. Used to keep track of each string sequentially. Brugglemark will increment this number by one for each bookmark generated.

| Aliases: | None |
| :-- | :-- |
| **Default Value:** | **0** |

### **`-bmGUID`**
Controls the value of the guid field in each bookmark created. The browser will overwrite this with a randomly generated GUID.

| Aliases: | None |
| :-- | :-- |
| **Default Value:** | **dp** |

### **`-bmID`**
Controls the value of the id field in each bookmark created. The browser will overwrite this with the sequential ordering of the bookmark.

| Aliases: | None |
| :-- | :-- |
| **Default Value:** | **1** |

### **`-bmType`**
Controls the value of the type field in each bookmark created. While this can be set to "url" or "folder" this script DOES NOT support generating folder entries at this time (aside from the one that is created to hold each bookmark).

| Aliases: | None |
| :-- | :-- |
| **Default Value:** | **url** |

### **`-bmURL`**
Controls the value of the url field in each bookmark created. Length of URL impacts the max length for the name field; the shorter, the better.

| Aliases: | None |
| :-- | :-- |
| **Default Value:** | **aa::** |

### **`-bmFolderRoot`**
TO DO [Not yet implemented]: Controls which folder root will be used: Bookmarks bar, Other bookmarks, or Mobile bookmarks.

| Aliases: | bmFR, FR |
| :-- | :-- |
| **Default Value:** | **Mobile bookmarks** |

### **`-bmFolderName`**
Controls the name of the folder that is created to store the generated bookmarks. An incrementing number is added if a folder with that name already exists.

| Aliases: | bmFN, FN |
| :-- | :-- |
| **Default Value:** | **brugglemark** |

### **`-bmFolderDateAdded`**
Controls the value of the date_added field in the bookmark folder created.

| Aliases: | None |
| :-- | :-- |
| **Default Value:** | **0** |

### **`-bmFolderDateModified`**
Controls the value of the date_modified field in the bookmark folder created.

| Aliases: | None |
| :-- | :-- |
| **Default Value:** | **0** |

## Credits
- Immense credit to **Chris White ([github.com/chriswhitehat/](https://github.com/chriswhitehat/))** for help with inserting the generated bookmarks into the Mobile bookmarks folder in the "Bookmarks" file, and for rewriting how bookmarks are generated (hash tables instead of arrays).
