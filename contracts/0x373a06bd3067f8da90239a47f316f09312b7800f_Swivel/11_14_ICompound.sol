// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface ICompound {
    function mint(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);
}