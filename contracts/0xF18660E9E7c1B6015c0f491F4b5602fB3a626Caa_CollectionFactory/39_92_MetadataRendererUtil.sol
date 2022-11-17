// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title Metadata Render Helper
 * @author [email protected], Zora
 * @dev Helper methods for Metadata Rendering
 */
library MetadataRendererUtil {
    /**
     * @param json Raw json to base64 and turn into a data-uri
     * @dev Encodes the argument json bytes into base64-data uri format
     */
    function encodeMetadataJSON(bytes memory json) internal pure returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }

    /**
     * @param value number to return as a string
     * @dev Proxy to openzeppelin's toString function
     */
    function numberToString(uint256 value) internal pure returns (string memory) {
        return Strings.toString(value);
    }
}