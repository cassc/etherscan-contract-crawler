// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBoostCalculator {
    function getBoostedAmountWrite(
        address account,
        uint256 amount,
        uint256 previousAmount,
        uint256 totalWeeklyEmissions
    ) external returns (uint256 adjustedAmount);

    function MAX_BOOST_GRACE_WEEKS() external view returns (uint256);

    function getBoostedAmount(
        address account,
        uint256 amount,
        uint256 previousAmount,
        uint256 totalWeeklyEmissions
    ) external view returns (uint256 adjustedAmount);

    function getClaimableWithBoost(
        address claimant,
        uint256 previousAmount,
        uint256 totalWeeklyEmissions
    ) external view returns (uint256 maxBoosted, uint256 boosted);

    function getWeek() external view returns (uint256 week);

    function locker() external view returns (address);
}