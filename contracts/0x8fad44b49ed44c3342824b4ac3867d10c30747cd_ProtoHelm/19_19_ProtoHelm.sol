// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./AllowlistFixedPrice721.sol";

contract ProtoHelm is AllowlistFixedPrice721 {
    constructor(string memory _uri, uint256 _mintPrice, uint256 _mintLimit, bytes32 _merkleRoot)
        AllowlistFixedPrice721(
            "Atmos | Emergent MKIV Proto Helm",
            "PROTO-HELM",
            _uri,
            _mintPrice,
            _mintLimit,
            512,
            _merkleRoot
        )
    {}
}