// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGooHolder {
    function totalGoo() external view returns (uint256);
    function depositGoo(uint256) external;
    function withdrawGoo(uint256, address) external;
    function addFee(uint256) external;
}