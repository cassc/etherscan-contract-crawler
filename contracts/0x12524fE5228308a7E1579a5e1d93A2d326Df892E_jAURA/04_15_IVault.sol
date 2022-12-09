// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVault {
    function convertToShares(uint256 assets) external view returns (uint256);

    function convertToAssets(uint256 assets) external view returns (uint256);

    function asset() external view returns (address);

    function totalWithdrawRequests() external view returns (uint256);
}