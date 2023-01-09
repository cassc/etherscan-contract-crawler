// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @title ISharedFunding
 * @notice Chainlink oracle to retrieve ETH-USD value
 */
interface IChainlinkOracle {
    /* ============== Function ============== */

    function latestRoundData()
        external
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        );
}