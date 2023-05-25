// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./AllowlistFree721.sol";

contract ExordiumTwo is AllowlistFree721 {
    constructor(string memory _uri, uint256 _mintLimit, bytes32 _merkleRoot)
        AllowlistFree721(
            "Atmos | Exordium Chapter 02",
            "EXORDIUM-02",
            _uri,
            _mintLimit,
            3000,
            _merkleRoot
        )
    {}
}