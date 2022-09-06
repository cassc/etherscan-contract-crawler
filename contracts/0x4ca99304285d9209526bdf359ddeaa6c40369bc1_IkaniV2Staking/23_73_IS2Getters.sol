// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IIkaniV2 } from "../../../nft/v2/interfaces/IIkaniV2.sol";
import { IS2Lib } from "../lib/IS2Lib.sol";
import { IS2Storage } from "./IS2Storage.sol";

/**
 * @title IS2Getters
 * @author Cyborg Labs, LLC
 *
 * @dev Simple getter functions that are only needed externally.
 */
abstract contract IS2Getters is
    IS2Storage
{
    //---------------- Constants ----------------//

    /// @dev Must match the value in IS2Lib.sol.
    uint256 public constant MULTIPLIER_BASE = 1e6;

    //---------------- External Functions ----------------//

    function isStaked(
        uint256 tokenId
    )
        external
        view
        override
        returns (bool)
    {
        return _TOKEN_STAKING_STATE_[tokenId].timestamp != 0;
    }

    function getStakedTimestamp(
        uint256 tokenId
    )
        external
        view
        returns (uint256)
    {
        return _TOKEN_STAKING_STATE_[tokenId].timestamp;
    }

    function getHistoricalBaseRate(
        uint256 i
    )
        external
        view
        returns (RateChange memory)
    {
        require(
            i <= _NUM_RATE_CHANGES_,
            "Invalid base rate index"
        );
        return _RATE_CHANGES_[i];
    }

    function getNumBaseRateChanges()
        external
        view
        returns (uint256)
    {
        return _NUM_RATE_CHANGES_;
    }

    function getAccountRewardsMultiplier(
        address account
    )
        external
        view
        returns (uint256)
    {
        return IS2Lib.getAccountRewardsMultiplier(_SETTLEMENT_CONTEXT_[account]);
    }

    function getFabricsRewardsMultiplier(
        address account
    )
        external
        view
        returns (uint256)
    {
        return IS2Lib.getFabricsRewardsMultiplier(_SETTLEMENT_CONTEXT_[account]);
    }

    function getSeasonsRewardsMultiplier(
        address account
    )
        external
        view
        returns (uint256)
    {
        return IS2Lib.getSeasonsRewardsMultiplier(_SETTLEMENT_CONTEXT_[account]);
    }

    function getNumFabricsStaked(
        address account
    )
        external
        view
        returns (uint256)
    {
        return IS2Lib.getNumFabricsStaked(_SETTLEMENT_CONTEXT_[account]);
    }

    function getNumSeasonsStaked(
        address account
    )
        external
        view
        returns (uint256)
    {
        return IS2Lib.getNumSeasonsStaked(_SETTLEMENT_CONTEXT_[account]);
    }

    /**
     * @notice Get the token rewards rate for a token.
     */
    function getTokenRewardsRate(
        uint256 tokenId
    )
        external
        view
        returns (uint256)
    {
        return (
            getBaseRate() *
            getDurationRewardsMultiplier(tokenId) *
            getFoilRewardsMultiplier(tokenId) /
            (MULTIPLIER_BASE * MULTIPLIER_BASE)
        );
    }

    /**
     * @notice Get the staked duration level for a token.
     */
    function getDurationLevel(
        uint256 tokenId
    )
        external
        view
        returns (uint256)
    {
        uint256 stakedTimestamp = _TOKEN_STAKING_STATE_[tokenId].timestamp;
        uint256 stakedDuration = block.timestamp - stakedTimestamp;
        return IS2Lib.getLevelForStakedDuration(stakedDuration);
    }

    //---------------- Public Functions ----------------//

    function getBaseRate()
        public
        view
        returns (uint256)
    {
        return _RATE_CHANGES_[_NUM_RATE_CHANGES_].baseRate;
    }

    function getDurationRewardsMultiplier(
        uint256 tokenId
    )
        public
        view
        returns (uint256)
    {
        uint256 stakedTimestamp = _TOKEN_STAKING_STATE_[tokenId].timestamp;

        // If the token is not staked, return multipler of 1.
        if (stakedTimestamp == 0) {
            return MULTIPLIER_BASE;
        }

        uint256 stakedDuration = block.timestamp - stakedTimestamp;
        return IS2Lib.getStakedDurationRewardsMultiplier(stakedDuration);
    }

    function getFoilRewardsMultiplier(
        uint256 tokenId
    )
        public
        view
        returns (uint256)
    {
        IIkaniV2.PoemTraits memory traits = IIkaniV2(IKANI).getPoemTraits(tokenId);
        return IS2Lib.getFoilRewardsMultiplier(traits);
    }
}