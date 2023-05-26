// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAuraVirtualVault {
    function deposit(address receiver, uint256 assets) external returns (uint256);
    function withdraw(address receiver, uint256 assets) external;
    function totalAssets() external view returns (uint256);
    function previewRedeem(uint256 _shares) external view returns (uint256);
    function burn(address _user, uint256 _shares) external;
    function virtualShares(address _user) external view returns (uint256);
}