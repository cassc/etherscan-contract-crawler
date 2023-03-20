// SPDX-License-Identifier: NONE

pragma solidity >= 0.8.0;

interface IWoofPack {
    function mint(address recipient, uint256 id, bool rare) external;
}