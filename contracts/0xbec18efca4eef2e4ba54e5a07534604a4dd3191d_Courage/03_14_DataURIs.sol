//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Base64.sol";

library DataURIs {
    string private constant JSON_PREFIX = "data:application/json;base64,";
    string private constant SVG_PREFIX = "data:image/svg+xml;base64,";

    function toJsonURI(string memory json)
        internal
        pure
        returns (string memory)
    {
        return toURI(JSON_PREFIX, json);
    }

    function toSvgURI(string memory svg) internal pure returns (string memory) {
        return toURI(SVG_PREFIX, svg);
    }

    function toURI(string memory prefix, string memory data)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(prefix, Base64.encode(bytes(data))));
    }
}