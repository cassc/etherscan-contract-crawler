pragma solidity 0.8.19;

//SPDX-License-Identifier: MIT

interface IChainLinkRegistry {
    function latestAnswer(address base, address quote) external view returns(int256 answer);

    function latestRoundData(address base, address quote) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function decimals(address base, address quote) external view returns (uint8);
}