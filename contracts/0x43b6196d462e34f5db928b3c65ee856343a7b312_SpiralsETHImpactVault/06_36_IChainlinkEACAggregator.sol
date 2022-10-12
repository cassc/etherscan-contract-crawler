// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// https://github.com/smartcontractkit/chainlink/blob/e1e78865d4f3e609e7977777d7fb0604913b63ed/contracts/src/v0.6/interfaces/AggregatorInterface.sol
interface IChainlinkEACAggregator {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    function decimals() external view returns (uint8);

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );

    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );
}