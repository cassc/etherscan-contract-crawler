// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract CuratedByToken {

    string private constant _GENERATOR = "https://tokenmaker.bitsforblocks.com";
    string private _version;

    constructor (string memory version_) {
        _version = version_;
    }

    /**
     * @dev Returns the token generator tool.
     */
    function curatedBy() public pure returns (string memory) {
        return _GENERATOR;
    }

    /**
     * @dev Returns the token generator version.
     */
    function version() public view returns (string memory) {
        return _version;
    }
}