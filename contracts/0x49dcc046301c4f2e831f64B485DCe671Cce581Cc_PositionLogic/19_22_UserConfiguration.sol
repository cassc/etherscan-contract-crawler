// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../types/DataTypes.sol";

library UserConfiguration {

    function setUsingReserve(
        DataTypes.UserConfiguration storage self,
        uint256 bitIndex,
        bool usingReserve
    ) internal {
        self.reserve = (self.reserve & ~(1 << bitIndex)) | (uint256(usingReserve ? 1 : 0) << bitIndex);
    }

    function setUsingCollateral(
        DataTypes.UserConfiguration storage self,
        uint256 bitIndex,
        bool usingCollateral
    ) internal {
        self.collateral = (self.collateral & ~(1 << bitIndex)) | (uint256(usingCollateral ? 1 : 0) << bitIndex);
    }

    function setUsingPosition(
        DataTypes.UserConfiguration storage self,
        uint256 bitIndex,
        bool usingPosition
    ) internal {
        self.position = (self.position & ~(1 << bitIndex)) | (uint256(usingPosition ? 1 : 0) << bitIndex);
    }

    function isUsingReserve(
        DataTypes.UserConfiguration memory self,
        uint256 bitIndex
    ) internal pure returns (bool) {
        return (self.reserve >> bitIndex) & 1 != 0;
    }

    function isUsingCollateral(
        DataTypes.UserConfiguration memory self,
        uint256 bitIndex
    ) internal pure returns (bool) {
        return (self.collateral >> bitIndex) & 1 != 0;
    }

    function isUsingPosition(
        DataTypes.UserConfiguration memory self,
        uint256 bitIndex
    ) internal pure returns (bool) {
        return (self.position >> bitIndex) & 1 != 0;
    }

    function hasReserve(
        DataTypes.UserConfiguration memory self,
        uint256 offSetIndex
    ) internal pure returns (bool) {
        return (self.reserve >> offSetIndex) > 0;
    }

    function hasCollateral(
        DataTypes.UserConfiguration memory self,
        uint256 offSetIndex
    ) internal pure returns (bool) {
        return (self.collateral >> offSetIndex) > 0;
    }

    function hasPosition(
        DataTypes.UserConfiguration memory self,
        uint256 offSetIndex
    ) internal pure returns (bool) {
        return (self.position >> offSetIndex) > 0;
    }

    function isEmpty(DataTypes.UserConfiguration memory self) internal pure returns (bool) {
        return self.reserve == 0 && self.collateral == 0 && self.position == 0;
    }
}