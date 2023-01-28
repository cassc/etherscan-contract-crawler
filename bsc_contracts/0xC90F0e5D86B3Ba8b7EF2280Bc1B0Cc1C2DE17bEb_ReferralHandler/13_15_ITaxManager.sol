// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ITaxManager {
    function getSelfTaxPool() external returns (address);
    function getRightUpTaxPool() external view returns (address);
    function getMaintenancePool() external view returns (address);
    function getDevPool() external view returns (address);
    function getRewardAllocationPool() external view returns (address);
    function getPerpetualPool() external view returns (address);
    function getTierPool() external view returns (address);
    function getMarketingPool() external view returns (address);
    function getRevenuePool() external view returns (address);

    function getSelfTaxRate() external view returns (uint256);
    function getRightUpTaxRate() external view returns (uint256);
    function getMaintenanceTaxRate() external view returns (uint256);
    function getProtocolTaxRate() external view returns (uint256);
    function getTotalTaxAtMint() external view returns (uint256);
    function getPerpetualPoolTaxRate() external view returns (uint256);
    function getTaxBaseDivisor() external view returns (uint256);
    function getReferralRate(uint256, uint256) external view returns (uint256);
    function getTierPoolRate() external view returns (uint256);
    // function getDevPoolRate() external view returns (uint256);
    function getMarketingTaxRate() external view returns (uint256);
    function getRewardPoolRate() external view returns (uint256);
}