// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @notice Copy-modified from 
///         https://github.com/chronicleprotocol/aggor/blob/master/src/interfaces/_external/IChainlinkAggregatorV3.sol
///         Supports deprecated interfaces.

interface IChainlink {
    /// @notice Get the number of decimals present in the response value.
    function decimals() external view returns (uint8);

    /// @notice Get the full information for the most recent round including
    ///         the answer and update timestamps.
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );

    /// @dev This interface is deprecated, you should not use it
    function latestAnswer() external view returns (int);
}