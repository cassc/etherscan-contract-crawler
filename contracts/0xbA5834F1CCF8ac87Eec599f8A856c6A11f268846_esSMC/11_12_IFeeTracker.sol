// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

interface IFeeTracker {
    function setShare(address shareholder, uint256 amount) external;
    function depositYield(uint256 _source, uint256 _fees) external;
    function addYieldSource(address _yieldSource) external;
    function withdrawYield() external;
}