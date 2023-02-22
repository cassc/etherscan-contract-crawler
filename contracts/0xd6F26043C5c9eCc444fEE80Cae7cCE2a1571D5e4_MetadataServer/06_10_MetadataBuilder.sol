// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Base64.sol";
import "./MetadataMIMETypes.sol";

library MetadataBuilder {
    struct JSONItem {
        string key;
        string value;
        bool quote;
    }

    function generateSVG(
        string memory contents,
        string memory viewBox,
        string memory width,
        string memory height
    ) internal pure returns (string memory) {
        return
            string.concat(
                //solhint-disable-next-line
                '<svg viewBox="',
                viewBox,
                //solhint-disable-next-line
                '" xmlns="http://www.w3.org/2000/svg" width="',
                //solhint-disable-next-line
                width,
                //solhint-disable-next-line
                '" height="',
                height,
                //solhint-disable-next-line
                '">',
                contents,
                "</svg>"
            );
    }

    /// @notice prefer to use properties with key-value object instead of list
    function generateAttributes(string memory displayType, string memory traitType, string memory value) internal pure returns (string memory) {

    }

    function generateEncodedSVG(
        string memory contents,
        string memory viewBox,
        string memory width,
        string memory height
    ) internal pure returns (string memory) {
        return
            encodeURI(
                MetadataMIMETypes.mimeSVG,
                generateSVG(contents, viewBox, width, height)
            );
    }

    function encodeURI(string memory uriType, string memory result)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                "data:",
                uriType,
                ";base64,",
                string(Base64.encode(bytes(result)))
            );
    }

    function generateJSONArray(JSONItem[] memory items)
        internal
        pure
        returns (string memory result)
    {
        result = "[";
        uint256 added = 0;
        for (uint256 i = 0; i < items.length; i++) {
            if (bytes(items[i].value).length == 0) {
                continue;
            }
            if (items[i].quote) {
                result = string.concat(
                    result,
                    added == 0 ? "" : ",",
                    //solhint-disable-next-line
                    '"',
                    items[i].value,
                    //solhint-disable-next-line
                    '"'
                );
            } else {
                result = string.concat(
                    result,
                    added == 0 ? "" : ",",
                    items[i].value
                );
            }
            added += 1;
        }
        result = string.concat(result, "]");
    }

    function generateJSON(JSONItem[] memory items)
        internal
        pure
        returns (string memory result)
    {
        result = "{";
        uint256 added = 0;
        for (uint256 i = 0; i < items.length; i++) {
            if (bytes(items[i].value).length == 0) {
                continue;
            }
            if (items[i].quote) {
                result = string.concat(
                    result,
                    added == 0 ? "" : ",",
                    //solhint-disable-next-line
                    '"',
                    items[i].key,
                    //solhint-disable-next-line
                    '": "',
                    items[i].value,
                    //solhint-disable-next-line
                    '"'
                );
            } else {
                result = string.concat(
                    result,
                    added == 0 ? "" : ",",
                    //solhint-disable-next-line
                    '"',
                    items[i].key,
                    //solhint-disable-next-line
                    '": ',
                    items[i].value
                );
            }
            added += 1;
        }
        result = string.concat(result, "}");
    }

    function generateEncodedJSON(JSONItem[] memory items)
        internal
        pure
        returns (string memory)
    {
        return encodeURI(MetadataMIMETypes.mimeJSON, generateJSON(items));
    }
}