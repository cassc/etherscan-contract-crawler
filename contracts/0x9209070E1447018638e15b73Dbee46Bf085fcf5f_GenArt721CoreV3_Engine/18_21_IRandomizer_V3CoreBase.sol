// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IRandomizer_V3CoreBase {
    // When a core contract calls this, it can be assured that the randomizer
    // will set a bytes32 hash for tokenId `_tokenId` on the core contract.
    function assignTokenHash(uint256 _tokenId) external;
}