# Exploring the API of a Zotrax M200 Plus Printer

## Printer discovery in local network

UDP packet on port `8001` with payload `Zortrax` to your broadcast.
You will reveive a response on the same port if there is compatible hardware present.

### UDP Response structure

| Field | Size (bytes) | Description |
| -- | -- | -- |
| Hardware Id | 1 | Each hardware has its distinct Id |
| Serial Number | 9 (variable) | Serial number of the device |

### Known Hardware Id numbers

| Dec | Hex | Hardware |
| --- | --- | -------- |
| 40 | 0x28 | Zortrax Inkspire |
| 24 | 0x18 | Zotrax M200+ |

## The protocol

Zotrax M200 Plus printer exposed protocol endpoint on port `8002`.  
The first two bytes are defining the payload length. Little Endian.
The rest is the payload.

| Field | Size (bytes) | Description |
| -- | -- | -- |
| Payload Size | 2 | Size in bytes of the Query field. Little endian order |
| Query | variable | |

The payload is a json formatted query.

## Query and Response Structure

### Generalized Query Structure

```json
{
  "commands": [
    {
      "fields": ["<field1>", "<field2>", ...],
      "type": "<commandType>"
    }
  ]
}
```

#### Query explanation

- **`commands`**: An array of command objects.
  - **`fields`**: A list of field names (strings) that the query requests data for.
  - **`type`**: The type of the command being issued (e.g., `version`, `printStatus`, `status`). The known mapping is given in later secion.

### Generalized Response Structure

```json
{
  "responses": [
    {
      "fields": [
        {
          "name": "<fieldName>",
          "value": <fieldValue>
        },
        ...
      ],
      "status": "<statusCode>",
      "type": "<responseType>"
    }
  ]
}
```

#### Response Eexplanation

- **`responses`**: An array of response objects.
  - **`fields`** : A list of field objects returned in response to the query.
    - **`name`**: The name of the field.
    - **`value`**: The value of the field. It can be a string, number, or another type depending on the field.
  - **`status`**: A status code as a string indicating the result of the command (e.g., `1` for success, `2` for failure or incomplete response - maybe (need more data)).
  - **`type`**: The type of the response corresponding to the `type` in the query.

### Mapping

| Command | Fields | Other | Details |
| -- | -- | -- | -- |
| `getSetting` | `lights`, `buzzer`, `sleep`, `nozzleDiameter` | N/A | |
| `printStatus` | `progress`, `metadata`, `userSettings`, `filename` | N/A | |
| `status` | `printerStatus`, `storageBytesFree`, `storageBytesTotal`, `currentMaterialId`, `serialNumber`, `printingInProgress`, `failsafeAlertReason`, `failsafeAlertSource` | N/A | |
| `version` | `protocol`, `firmware`, `software`, `hardware` | N/A | |
| `getCameraPreview` | N/A | `quality` | No fields required. |
| `printFromStorage` | N/A | `forced`, `path` | |

### Examples

#### Query 1: Version Command

**Query:**

```json
{
  "commands": [
    {
      "fields": ["protocol", "firmware", "software", "hardware"],
      "type": "version"
    }
  ]
}
```

**Response:**

```json
{
  "responses": [
    {
      "fields": [
        {"name": "protocol", "value": 1},
        {"name": "firmware", "value": "2.6.15"},
        {"name": "software", "value": 23727},
        {"name": "hardware", "value": 24}
      ],
      "status": "1",
      "type": "version"
    }
  ]
}
```

#### Query 2: Print Status Command

**Query:**

```json
{
  "commands": [
    {
      "fields": ["progress", "metadata", "userSettings", "filename"],
      "type": "printStatus"
    }
  ]
}
```

**Response:**

If currently not printing status is 2.

```json
{
  "responses": [
    {
      "status": "2",
      "type": "printStatus"
    }
  ]
}
```

If print started (after heating phase) then the status is 1.

```json
{
  "responses": [
    {
      "fields": [
        {
          "name": "progress",
          "value": 5
        },
        {
          "name": "metadata",
          "value": "<base64 metadata on the zcodex2 file>"
        },
        {
          "name": "userSettings",
          "value": ""
        },
        {
          "name": "filename",
          "value": "CurrentlyPrintedFilename.zcodex2"
        }
      ],
      "status": "1",
      "type": "printStatus"
    }
  ]
}
```

#### Query 3: Status Command

**Query:**

```json
{
  "commands": [
    {
      "fields": [
        "printerStatus", "storageBytesFree", "storageBytesTotal",
        "currentMaterialId", "serialNumber", "printingInProgress",
        "failsafeAlertReason", "failsafeAlertSource"
      ],
      "type": "status"
    }
  ]
}
```

**Response:**

```json
{
  "responses": [
    {
      "fields": [
        {"name": "printerStatus", "value": "printing_complete"},
        {"name": "storageBytesFree", "value": 15289991168},
        {"name": "storageBytesTotal", "value": 15367913472},
        {"name": "currentMaterialId", "value": 128},
        {"name": "serialNumber", "value": "ZXXXFYYYY"},
        {"name": "printingInProgress", "value": 1},
        {"name": "failsafeAlertReason", "value": 5},
        {"name": "failsafeAlertSource", "value": 5}
      ],
      "status": "1",
      "type": "status"
    }
  ]
}
```

`printerStatus` might be in: `busy` `printing` `heating` `printing_complete` `idle`

#### Query 4: Print a file

```json
{
  "commands": [
    {
      "path": "PathToYourFile.zcodex2",
      "forced": false,
      "type": "printFromStorage"
    }
  ]
}
```

**Response:**

```json
{
  "responses": [
    {
      "status": "1",
      "type": "printFromStorage"
    }
  ]
}
```

## Commands shortcuts

### Get Camera image

```bash
./query_file.sh -q camera.json -i MY_PRINTER_IP -p 8002 ./query_file.sh | jq -r ".responses[0].cameraPreviewData" | base64 -d > out.jpeg
```

## Sending Files

The M200 Plus printer serves an FTP server on port 8003. Credentials are user: `zortrax`, password: `zortrax`.

## Other findings

A file `failInformation.txt` appears in some cases in the printer files. Apparently its encrypted.
