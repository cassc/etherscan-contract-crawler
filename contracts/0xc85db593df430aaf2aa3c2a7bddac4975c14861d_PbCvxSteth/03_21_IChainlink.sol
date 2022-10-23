// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IChainlink {
    function latestRoundData() external view returns (uint80 roundId, int answer, uint startedAt, uint updatedAt, uint80 answeredInRound);
}