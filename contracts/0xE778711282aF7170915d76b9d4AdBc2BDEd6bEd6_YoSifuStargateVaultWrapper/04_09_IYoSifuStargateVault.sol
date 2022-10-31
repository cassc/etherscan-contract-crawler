// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IYoSifuStargateVault {
     function deposit(uint256 assets, address receiver)
        external
        returns (uint256 shares);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    function underlyingAsset() external view returns (address);

    function asset() external view returns (address);

    function poolId() external view returns (uint256);

    function previewDeposit(uint256 assets) external view returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);
}