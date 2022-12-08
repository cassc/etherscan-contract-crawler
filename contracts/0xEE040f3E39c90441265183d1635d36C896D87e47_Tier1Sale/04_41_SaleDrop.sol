// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface SaleDrop {
    function getPrice() external view returns (uint256);

    function isSoldOut() external view returns (bool);

    function getTotalSold() external view returns (uint256);

    function getTotalLeft() external view returns (uint256);

    function buy() external payable returns (uint);
    
}