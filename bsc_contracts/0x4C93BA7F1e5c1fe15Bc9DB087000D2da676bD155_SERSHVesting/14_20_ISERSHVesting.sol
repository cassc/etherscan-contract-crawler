// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DataTypes} from "../libraries/DataTypes.sol";

interface ISERSHVesting {
    function getVersion() external view returns (uint);

    function getVestingToken() external view returns (address);

    function getTotalVested() external view returns (uint256);

    function getTotalVestingAmount(
        address buyer
    ) external view returns (uint256);

    function isVestingContract(address vesting) external view returns (bool);

    function getPaused() external view returns (bool);

    function getMinVestingAmount() external view returns (uint256);

    function getMaxVestingAmount() external view returns (uint256);

    function getSubWallet(
        DataTypes.VestingCategory category
    ) external view returns (address);

    function getCategoryTotalVested(
        DataTypes.VestingCategory category
    ) external view returns (uint256);

    function getVestingPlan(
        DataTypes.VestingCategory category
    )
        external
        view
        returns (
            uint cliff,
            uint linear,
            uint256 tgeRate,
            uint256 cliffRate,
            uint256 vestingRate
        );

    function getTGETimestamp() external view returns (uint256);

    function triggerUnvestedEvent(string memory requestHash, address vesting, address receiver,  uint256 amount, uint256 when, uint8 finished, uint64 oldstep) external;
}