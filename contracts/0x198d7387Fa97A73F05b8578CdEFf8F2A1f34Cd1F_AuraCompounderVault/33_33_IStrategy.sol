// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IStrategy {
    function totalAssets() external view returns (uint256);
    function totalAssetsLSD() external view returns (uint256);
    function totalNoTokenizedAssets() external view returns (uint256);

    function deposit(uint256 auraAmount, bool tokenized) external;
    function withdrawRetention() external view returns (address recipient, uint64 percent);
    function withdraw(address user, uint256 amount, bool tokenized) external returns (uint256);

    function afterRehyphotecate(uint256 auraAmount, bool tokenized) external;

    function vaultsPosition() external view returns (uint256, uint256);
}