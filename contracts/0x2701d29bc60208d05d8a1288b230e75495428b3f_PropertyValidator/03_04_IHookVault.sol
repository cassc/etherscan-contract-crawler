// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IHookVault {
    function assetTokenId(uint32 assetId) external view returns (uint256);
}