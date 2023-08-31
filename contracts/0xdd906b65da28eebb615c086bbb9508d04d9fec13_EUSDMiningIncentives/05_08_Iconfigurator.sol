// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

interface Iconfigurator {
    function mintVault(address pool) external view returns(bool);
    function mintVaultMaxSupply(address pool) external view returns(uint256);
    function vaultMintPaused(address pool) external view returns(bool);
    function vaultBurnPaused(address pool) external view returns(bool);
    function tokenMiner(address pool) external view returns(bool);
    function getSafeCollateralRatio(address pool) external view returns(uint256);
    function getBadCollateralRatio(address pool) external view returns(uint256);
    function getVaultWeight(address pool) external view returns (uint256);
    function vaultMintFeeApy(address pool) external view returns(uint256);
    function vaultKeeperRatio(address pool) external view returns(uint256);
    function redemptionFee() external view returns(uint256);
    function getEUSDAddress() external view returns(address);
    function peUSD() external view returns(address);
    function eUSDMiningIncentives() external view returns(address);
    function getProtocolRewardsPool() external view returns(address);
    function flashloanFee() external view returns(uint256);
    function getEUSDMaxLocked() external view returns (uint256);
    function stableToken() external view returns (address);
    function isRedemptionProvider(address user) external view returns (bool);
    function becomeRedemptionProvider(bool _bool) external;
    function refreshMintReward(address user) external;
    function distributeRewards() external;
    function hasRole(bytes32 role, address account) external view returns (bool);
}