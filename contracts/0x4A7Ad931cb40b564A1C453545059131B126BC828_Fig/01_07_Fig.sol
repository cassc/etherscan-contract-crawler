// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import {IChronicle} from "chronicle-std/IChronicle.sol";
import {Auth} from "chronicle-std/auth/Auth.sol";
import {Toll} from "chronicle-std/toll/Toll.sol";

import {IChainlink} from "./IChainlink.sol";

interface IMakerMedianizer is IChronicle {
    /// @notice Returns the age of the current value.
    /// @return age The age of the current value.
    function age() external view returns (uint32 age);
}

/**
 * @title Fig
 * @custom:version 0.1.0
 *
 * @notice Fig provides Chainlink compatible interfaces for consuming Maker
 *         medianizers.
 */
contract Fig is IChainlink, Auth, Toll {
    /// @notice This is the legacy (i.e. Maker) medianizer contract
    address public immutable medianizer;

    constructor(address medianizer_) {
        medianizer = medianizer_;
    }

    /// @inheritdoc IChainlink
    uint8 public constant decimals = 8;

    /// @inheritdoc IChainlink
    /// @dev Will revert on overflow, solc 0.8+
    function latestAnswer() external view toll returns (int) {
        return int(IMakerMedianizer(medianizer).read() / 10**10);
    }

    /// @inheritdoc IChainlink
    /// @notice Where we don't have corollaries for all of the values below,
    //          we return 0.
    function latestRoundData()
        external
        view
        toll
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        ) {
            answeredInRound = roundId = 1;
            answer = int(IMakerMedianizer(medianizer).read() / 10**10);
            startedAt = 0;
            updatedAt = uint(IMakerMedianizer(medianizer).age());
    }

    // -- Overridden Toll Functions --

    /// @dev Defines authorization for IToll's authenticated functions.
    function toll_auth() internal override(Toll) auth {}
}