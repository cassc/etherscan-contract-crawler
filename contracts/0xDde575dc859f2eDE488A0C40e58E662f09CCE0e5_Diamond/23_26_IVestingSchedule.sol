// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVestingSchedule {
    function getVestingSchedule(
        address _beneficiary
    )
        external
        view
        returns (
            bool initialized,
            address beneficiary,
            uint256 cliff,
            uint256 start,
            uint256 duration,
            uint256 slicePeriodSeconds,
            uint256 amountTotal,
            uint256 released
        );

    function computeReleasableAmount(
        address _beneficiary
    ) external view returns (uint256);
}