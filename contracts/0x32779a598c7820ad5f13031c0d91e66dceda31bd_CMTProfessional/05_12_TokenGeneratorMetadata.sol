// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title TokenGeneratorMetadata
 * @author Create My Token (https://www.createmytoken.com/)
 * @dev Implementation of the TokenGeneratorMetadata
 */
contract TokenGeneratorMetadata {
    string private constant _GENERATOR = "https://www.createmytoken.com/";
    string private constant _VERSION = "v1.0.8";

    /**
     * @dev Returns the token generator metadata.
     */
    function generator() public pure returns (string memory) {
        return _GENERATOR;
    }

    /**
     * @dev Returns the token generator version.
     */
    function version() public pure returns (string memory) {
        return _VERSION;
    }
}