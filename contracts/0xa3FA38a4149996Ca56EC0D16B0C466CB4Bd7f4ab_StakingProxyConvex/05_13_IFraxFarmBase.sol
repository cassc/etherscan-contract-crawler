// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IFraxFarmBase{

    function totalLiquidityLocked() external view returns (uint256);
    function lockedLiquidityOf(address account) external view returns (uint256);

    function toggleValidVeFXSProxy(address proxy_address) external;
    function proxyToggleStaker(address staker_address) external;
    function stakerSetVeFXSProxy(address proxy_address) external;
    function getReward(address destination_address) external returns (uint256[] memory);

}