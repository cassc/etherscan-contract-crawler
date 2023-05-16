// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

interface IVirtualPriceStableSwap {
    function get_virtual_price() external view returns (uint256);
}