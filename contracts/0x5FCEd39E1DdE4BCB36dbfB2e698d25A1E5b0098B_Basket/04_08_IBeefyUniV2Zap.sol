// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface IBeefyUniV2Zap {
    function beefIn (address beefyVault, uint256 tokenAmountOutMin, address tokenIn, uint256 tokenInAmount) external;
    function beefInETH (address beefyVault, uint256 tokenAmountOutMin) external payable;
    function beefOut (address beefyVault, uint256 withdrawAmount) external;
}