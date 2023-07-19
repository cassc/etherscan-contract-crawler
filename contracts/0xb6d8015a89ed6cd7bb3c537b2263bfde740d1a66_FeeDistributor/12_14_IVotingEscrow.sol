//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {DataTypes} from "../libraries/types/DataTypes.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";

interface IVotingEscrow {
    event CreateLock(
        address indexed receiver,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 unlockTime
    );
    event IncreaseAmount(uint256 indexed tokenId, uint256 amount);

    event IncreaseUnlockTime(uint256 indexed tokenId, uint256 unlockTime);

    event Withdraw(uint256 indexed tokenId);

    event ClaimRebates(
        address indexed receiver,
        uint256 indexed tokenId,
        uint256 amount
    );

    function getLockHistoryLength(
        uint256 tokenId
    ) external view returns (uint256);

    function getEpochPeriod() external pure returns (uint256);

    function getEpoch(uint256 timestamp) external view returns (uint256);

    function getEpochTimestamp(uint256 epoch_) external returns (uint256);

    function writeTotalWeightHistory() external;

    function getLockHistoryPoint(
        uint256 tokenId,
        uint256 index
    ) external view returns (DataTypes.Point memory);

    function getLockedRatioAt(uint256 _epoch) external returns (uint256);

    function getTotalWeightAt(uint256 epoch_) external returns (uint256);

    function getTotalWeight() external returns (uint256);

    function getUserWeight(address user) external view returns (uint256);

    function createLock(
        address receiver,
        uint256 amount,
        uint256 unlockTime
    ) external;

    function getLock(
        uint256 tokenId
    ) external view returns (DataTypes.LockedBalance memory);
}