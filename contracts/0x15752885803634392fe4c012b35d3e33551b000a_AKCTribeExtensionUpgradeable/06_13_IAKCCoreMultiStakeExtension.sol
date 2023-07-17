// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract IAKCCoreMultiStakeExtension {
    /**
     * STAKING
     */

    function kongToStaker(uint256) public view returns (uint256) {}
    function stake(address staker, uint256 spec, uint256 kong) external {}
    function unstake(address staker, uint256 spec, uint256 kong) external {}
    function userToStakeData(address user, uint256 spec) public view returns (uint256) {}

    function addToBonus(address staker, uint256 spec, uint256 bonus) external {}
    function getBonus(address staker, uint256 spec) external view returns (uint256) {}
    function liquidateBonus(address staker, uint256 spec) external returns (uint256) {}
    function liquidateBonusView(address staker, uint256 spec) external view returns (uint256) {}
    function getStakePendingBonusFromStakeData(uint256 stakeData) external pure returns (uint256) {}

    function getNakedRewardBySpec(address staker, uint256 targetSpec, uint256 timestamp)
        external
        view
        returns (uint256)
    {}

}