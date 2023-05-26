// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IAggregatorV3 } from "./IAggregatorV3.sol";
import { RoundData } from "../Structs.sol";

interface IOracle is IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function cegaState() external view returns (address);

    function oracleData() external view returns (RoundData[] memory);

    function nextRoundId() external view returns (uint80);

    function addNextRoundData(RoundData calldata _roundData) external;

    function updateRoundData(uint80 roundId, RoundData calldata _roundData) external;

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}