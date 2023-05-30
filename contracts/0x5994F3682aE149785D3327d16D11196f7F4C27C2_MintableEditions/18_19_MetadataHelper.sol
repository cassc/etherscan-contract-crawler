// SPDX-License-Identifier: MIT

/**
 * ░█▄█░▄▀▄▒█▀▒▄▀▄░░░▒░░░▒██▀░█▀▄░█░▀█▀░█░▄▀▄░█▄░█░▄▀▀░░░█▄░█▒█▀░▀█▀
 * ▒█▒█░▀▄▀░█▀░█▀█▒░░▀▀▒░░█▄▄▒█▄▀░█░▒█▒░█░▀▄▀░█▒▀█▒▄██▒░░█▒▀█░█▀░▒█▒
 * 
 * Made with 🧡 by Kreation.tech
 */
pragma solidity ^0.8.6;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {Base64} from "base64-sol/base64.sol";

/**
 * Shared utility functions for rendering on-chain metadata
 */
contract MetadataHelper {
    /**
     * @param unencoded bytes to base64-encode
     */
    function base64Encode(bytes memory unencoded) public pure returns (string memory) {
        return Base64.encode(unencoded);
    }

    /**
     * Encodes the argument json bytes into base64-data uri format
     * 
     * @param json raw json to base64 and turn into a data-uri
     */
    function encodeMetadata(bytes memory json) public pure returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", base64Encode(json)));
    }

    /**
     * Proxy to openzeppelin's toString function
     *
     * @param value number to return as a string
     */
    function numberToString(uint256 value) public pure returns (string memory) {
        return StringsUpgradeable.toString(value);
    }
}