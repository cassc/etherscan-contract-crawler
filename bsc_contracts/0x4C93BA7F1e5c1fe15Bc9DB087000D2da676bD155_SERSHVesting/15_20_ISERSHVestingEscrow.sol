// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DataTypes} from "../libraries/DataTypes.sol";


interface ISERSHVestingEscrow  {

    function getVersion() external view returns (uint);

    function getBuyer() external view returns (address);

    function isFinished() external view returns (bool);

    function getVestingData() external view returns (
            uint256 amount,
            DataTypes.VestingCategory category,
            uint256 beginAt,
            address buyer,
            uint cliffMonths,
            uint linearMonths,
            uint256 tgeRate,
            uint256 cliffRate,
            uint256 vestingRate,
            string memory requestHash,
            address receiver,
            address buyer2
        );

    function setReceiver (address receiver) external ;

    function getNextTimeForUnvesting(uint64 nextStep) external view returns (uint256, uint64);

    function getUnvestingAmount(uint64 step) external view returns (uint256);
    function unvesting () external ;

    function canUnvesting() external view returns (bool, string memory);

}