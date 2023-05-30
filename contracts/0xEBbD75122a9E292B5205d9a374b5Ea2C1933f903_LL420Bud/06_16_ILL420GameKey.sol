// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ILL420GameKey {
    function balanceOf(address account) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function verifyOwnershipBatch(address user, uint256[] memory tokenIds) external view returns (bool);
}