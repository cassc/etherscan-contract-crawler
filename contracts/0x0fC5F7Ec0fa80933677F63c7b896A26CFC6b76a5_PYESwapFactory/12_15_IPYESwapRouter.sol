// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IPYESwapRouter {
    function pairFeeAddress(address pair) external view returns (address);
    function adminFee() external view returns (uint256);
    function feeAddressGet() external view returns (address);
    function adminFeeAddress() external view returns (address);
    function owner() external view returns (address);
}