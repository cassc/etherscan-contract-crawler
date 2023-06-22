// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IEd3Educators {
    function purchase(uint256 numberOfTokens) external payable;

    function purchasePreSale(uint256 numberOfTokens) external payable;

    function reserve(uint256 numberOfTokens) external;

    function setIsActive(bool isActive) external;

    function setIsPreSaleActive(bool isAllowListActive) external;

    function withdraw() external;
}