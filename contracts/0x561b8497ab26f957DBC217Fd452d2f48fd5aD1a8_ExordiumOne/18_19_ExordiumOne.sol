// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./AllowlistFree721.sol";

contract ExordiumOne is AllowlistFree721 {
    constructor(string memory _uri, uint256 _mintLimit, bytes32 _merkleRoot)
        AllowlistFree721(
            "Atmos | Exordium Chapter 01",
            "EXORDIUM-01",
            _uri,
            _mintLimit,
            2500,
            _merkleRoot
        )
    {}
}