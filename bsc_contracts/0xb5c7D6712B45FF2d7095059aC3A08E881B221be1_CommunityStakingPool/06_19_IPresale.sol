// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPresale {
    function endTime() external view returns (uint64);
    function buy() external payable;
}