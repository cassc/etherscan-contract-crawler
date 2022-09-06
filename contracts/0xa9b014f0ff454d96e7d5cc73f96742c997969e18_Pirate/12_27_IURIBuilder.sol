// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./TraitSet.sol";

interface IURIBuilder {
    function build(uint256 tokenId, TraitSet calldata traits) external view returns (string memory);
}