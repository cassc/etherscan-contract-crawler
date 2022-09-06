// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


interface IUniswapAnchoredView {
    function getUnderlyingPrice(address) external view returns (uint256);
}