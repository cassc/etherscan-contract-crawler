// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "./ITheCreepz.sol";

interface ITheCreepzDescriptor {
    function tokenURI(ITheCreepz thecreepz, uint256 tokenId) external view returns (string memory);
}