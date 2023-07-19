//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface IGaugeController {
    event Vote(
        address indexed user,
        uint256 indexed tokenId,
        address indexed gauge,
        uint256 weight
    );

    event AddGauge(address indexed gauge, address indexed liquidityPool);

    event RemoveGauge(address indexed gauge, address indexed liquidityPool);

    function isGauge(address gauge) external view returns (bool);

    function getLockVoteRatio(uint256 tokenId) external view returns (uint256);

    function getGaugeWeightAt(
        address gauge,
        uint256 epoch
    ) external returns (uint256);

    function getGaugeRewards(
        address gauge,
        uint256 epoch
    ) external returns (uint256 rewards);

    function getEpochRewards(uint256 epoch) external returns (uint256 rewards);

    function getLockVotePointForGauge(
        uint256 tokenId,
        address gauge
    ) external view returns (DataTypes.Point memory);

    function getLPMaturityPeriod() external view returns (uint256);
}