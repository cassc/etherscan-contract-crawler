// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Base64} from "./Base64.sol";
import {Util} from "./Util.sol";

library Metadata {
    string constant JSON_BASE64_HEADER = "data:application/json;base64,";
    string constant SVG_XML_BASE64_HEADER = "data:image/svg+xml;base64,";

    function encodeMetadata(
        uint256 _tokenId,
        string memory _name,
        string memory _description,
        // string memory _attributes,
        // string memory _backgroundColor,
        string memory _svg
    ) internal pure returns (string memory) {
        string memory metadata = string.concat(
            "{",
            Util.keyValue("tokenId", Util.uint256ToString(_tokenId)),
            ",",
            Util.keyValue("name", _name),
            ",",
            Util.keyValue("description", _description),
            // ",",
            // Util.keyValueNoQuotes("attributes", _attributes),
            // ",",
            // Util.keyValue("backgroundColor", _backgroundColor),
            ",",
            Util.keyValue("image", _encodeSVG(_svg)),
            "}"
        );

        return _encodeJSON(metadata);
    }

    /// @notice base64 encode json
    /// @param _json, stringified json
    /// @return string, bytes64 encoded json with prefix
    function _encodeJSON(string memory _json) internal pure returns (string memory) {
        return string.concat(JSON_BASE64_HEADER, Base64.encode(_json));
    }

    /// @notice base64 encode svg
    /// @param _svg, stringified json
    /// @return string, bytes64 encoded svg with prefix
    function _encodeSVG(string memory _svg) internal pure returns (string memory) {
        return string.concat(SVG_XML_BASE64_HEADER, Base64.encode(bytes(_svg)));
    }
}