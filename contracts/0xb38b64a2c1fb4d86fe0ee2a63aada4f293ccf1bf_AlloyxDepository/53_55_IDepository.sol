// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

struct DepositoryState {
    uint256 netAssetDeposits;
    uint256 insuranceDeposited;
    uint256 redeemableUnderManagement;
    uint256 totalFeesPaid;
    uint256 redeemableSoftCap;
}

interface IDepository {

    function assetToken() external view returns (address);
    function netAssetDeposits() external view returns (uint256);
    function supportedAssets() external view returns (address[] memory);

    function deposit(address token, uint256 amount) external returns (uint256);
    function redeem(address token, uint256 amountToRedeem) external returns (uint256);

    function transferOwnership(address newOwner) external;
    
    function getUnrealizedPnl() external view returns (int256);
}