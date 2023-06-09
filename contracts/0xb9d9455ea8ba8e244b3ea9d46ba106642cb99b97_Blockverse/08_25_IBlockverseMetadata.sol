// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IBlockverse.sol";

interface IBlockverseMetadata {
    function tokenURI(uint256 tokenId, IBlockverse.BlockverseFaction faction) external view returns (string memory);
}