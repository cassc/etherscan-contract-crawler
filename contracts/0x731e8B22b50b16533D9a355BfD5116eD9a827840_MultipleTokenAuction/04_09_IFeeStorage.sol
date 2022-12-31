// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFeeStorage {
    function feeInfo(address token_address, uint256 salePrice) external view returns (address[] memory, uint256[] memory, uint256);
}