// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {sub, wdiv} from "fiat/core/utils/Math.sol";
import {ICollybus} from "fiat/interfaces/ICollybus.sol";

import {OptimisticOracle} from "./OptimisticOracle.sol";
import {IOptimisticChainlinkValue} from "./interfaces/IOptimisticChainlinkValue.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";

/// @title OptimisticChainlinkOracle
/// @notice An Implementation of the OptimisticOracle for single value Chainlink feeds.
/// Assumptions: If a Chainlink Aggregator is not working as intended (e.g. calls revert (excl. getRoundData))
/// then the methods `value` and `validate` and subsequently `dispute` will revert as well
contract OptimisticChainlinkOracle is
    IOptimisticChainlinkValue,
    OptimisticOracle
{
    /// ======== Custom Errors ======== ///

    error OptimisticChainlinkOracle__value_feedNotFound(address token);
    error OptimisticChainlinkOracle__validate_feedNotFound(address token);
    error OptimisticChainlinkOracle__value_invalidTimestamp();
    error OptimisticChainlinkOracle__encodeNonce_activeDisputeWindow();
    error OptimisticChainlinkOracle__encodeNonce_staleProposal();
    error OptimisticChainlinkOracle__push_inactiveRateId();

    /// ======== Storage ======== ///

    // @notice Chainlink Feeds
    // Token => Chainlink Feed
    mapping(address => address) public feeds;

    /// @notice A proposals validation result, as determined in `validate`
    enum ValidateResult {
        Success,
        InvalidNonce,
        InvalidRound,
        InvalidValue
    }

    /// ======== Events ======== ///

    event FeedSet(address token, address feed);
    event FeedUnset(address token);

    /// @param target Address of target
    /// @param oracleType Unique identifier
    /// @param bondToken Address of the ERC20 token used by the bonding proposers
    /// @param bondSize Amount of `bondToken` a proposer has to bond in order to submit proposals for each `rateId`
    /// @param disputeWindow Period until a proposed value can not be disputed anymore [seconds]
    constructor(
        address target,
        bytes32 oracleType,
        IERC20 bondToken,
        uint256 bondSize,
        uint256 disputeWindow
    )
        OptimisticOracle(target, oracleType, bondToken, bondSize, disputeWindow)
    {}

    /// ======== Chainlink Feed Configuration ======== ///

    /// @notice Sets a Chainlink feed for given token
    /// @param token Address of the token corresponding to the Chainlink feed
    /// @param feed Address of the Chainlink feed
    function setFeed(address token, address feed) external checkCaller {
        feeds[token] = feed;
        emit FeedSet(token, feed);
    }

    /// @notice Unsets a Chainlink feed associated with `token`
    /// @param token Address of the token
    function unsetFeed(address token) external checkCaller {
        delete feeds[token];
        emit FeedUnset(token);
    }

    /// ======== Chainlink Oracle Implementation ======== ///

    /// @notice Retrieves the latest spot price for a `token` from the corresponding Chainlink feed
    /// @dev Assumes that the Chainlink Aggregator works as intended
    /// @param token Address of the `token` for which to retrieve the spot price
    /// @return value_ Spot price retrieved from the latest round data [wad]
    /// @return data Additional data retrieved from the latest round data [(roundId[uint80], roundTimestamp[uint64])]
    function value(address token)
        public
        view
        override(IOptimisticChainlinkValue)
        returns (uint256 value_, bytes memory data)
    {
        address feed = feeds[token];
        if (feed == address(0))
            revert OptimisticChainlinkOracle__value_feedNotFound(token);

        (
            uint80 roundId,
            int256 feedValue,
            ,
            uint256 roundTimestamp,

        ) = AggregatorV3Interface(feed).latestRoundData();

        if (roundTimestamp > type(uint64).max)
            revert OptimisticChainlinkOracle__value_invalidTimestamp();

        unchecked {
            value_ = wdiv(
                uint256(feedValue),
                10**AggregatorV3Interface(feed).decimals()
            );
        }

        // encode the roundId and roundTimestamp as `data`
        data = abi.encode(roundId, uint64(roundTimestamp));
    }

    /// ======== Proposal Management ======== ///

    /// @notice Validates `proposedValue` for given `nonce` via the corresponding Chainlink feed
    /// @dev Reverts if no Chainlink feed exists for the given `rateId`
    /// @param proposedValue Value to be validated [wad]
    /// @param rateId RateId (see target) of the proposal being validated
    /// @param nonce Nonce of the `value_` [roundId, roundTimestamp, proposeTimestamp]
    /// @return result Result of the validation [ValidateResult]
    /// @return validValue Value that was retrieved from the Chainlink feed [wad]
    /// @return validData Data corresponding to `validValue`
    function validate(
        uint256 proposedValue,
        bytes32 rateId,
        bytes32 nonce,
        bytes memory /*data*/
    )
        public
        view
        override(OptimisticOracle)
        returns (
            uint256 result,
            uint256 validValue,
            bytes memory validData
        )
    {
        // check that there's a Chainlink feed registered for `token`
        address token = address(uint160(uint256(rateId)));
        address feed = feeds[token];
        if (feed == address(0))
            revert OptimisticChainlinkOracle__validate_feedNotFound(token);

        // validate `proposedValue` and `nonce` data against the Chainlink data
        {
            (uint80 nonceRoundId, uint64 nonceTimestamp, ) = _decodeNonce(
                nonce
            );
            (
                uint256 roundValue,
                uint256 roundTimestamp
            ) = _tryFetchingRoundData(feed, nonceRoundId);
            if (roundValue == 0 && roundTimestamp == 0)
                result = uint256(ValidateResult.InvalidRound);
            else if (nonceTimestamp != uint64(roundTimestamp))
                result = uint256(ValidateResult.InvalidNonce);
            else if (proposedValue != roundValue)
                result = uint256(ValidateResult.InvalidValue);
        }

        // return `proposedValue` and `data` if the validation succeeded
        if (result == uint256(ValidateResult.Success)) {
            validValue = proposedValue;
        } else {
            // return latest round data from Chainlink if the validation failed
            (validValue, validData) = value(token);
        }
    }

    /// @notice Fetches round data from a Chainlink Aggregator feed for a given roundId
    /// @param feed Address of the Chainlink Aggregator
    /// @param roundId RoundId of the Chainlink Aggregator to fetch round data for
    /// @return roundValue Value fetched for the given `roundId` [wad]
    /// @return roundTimestamp Timestamp of the fetched round data [seconds]
    function _tryFetchingRoundData(address feed, uint256 roundId)
        private
        view
        returns (uint256 roundValue, uint256 roundTimestamp)
    {
        try AggregatorV3Interface(feed).getRoundData(uint80(roundId)) returns (
            uint80, /*roundId*/
            int256 roundValue_,
            uint256, /*startedAt*/
            uint256 roundTimestamp_,
            uint80 /*answeredInRound*/
        ) {
            unchecked {
                roundValue = wdiv(
                    uint256(roundValue_),
                    10**AggregatorV3Interface(feed).decimals()
                );
            }
            roundTimestamp = roundTimestamp_;
        } catch {}
    }

    /// @notice Pushes a value directly to target by computing it on-chain
    /// without going through the shift / dispute process
    /// @dev Overwrites the current queued proposal with the blank (initial) proposal
    /// @param rateId RateId (see target)
    function push(bytes32 rateId) public override(OptimisticOracle) {
        if (!activeRateIds[rateId])
            revert OptimisticChainlinkOracle__push_inactiveRateId();

        address token = address(uint160(uint256(rateId)));

        address feed = feeds[token];
        (
            ,
            int256 feedValue,
            ,
            uint256 roundTimestamp,

        ) = AggregatorV3Interface(feed).latestRoundData();

        uint256 value_ = 0;
        unchecked {
            value_ = wdiv(
                uint256(feedValue),
                10**AggregatorV3Interface(feed).decimals()
            );
        }

        bytes32 nonce = _encodeNonce(0, uint64(roundTimestamp), 0);

        // reset the current proposal to the initial state
        proposals[rateId] = computeProposalId(rateId, address(0), 0, nonce);

        // push the value to target
        _push(rateId, value_);

        emit Push(rateId, nonce, value_);
    }

    /// @notice Pushes a proposed value to target
    /// @param rateId RateId (see target)
    /// @param value_ Value that will be pushed to target [wad]
    function _push(bytes32 rateId, uint256 value_)
        internal
        override(OptimisticOracle)
    {
        // the OptimisticOracle ignores any exceptions that could be raised in the contract where the values are pushed
        // to - otherwise the shift / dispute flow would halt
        try
            ICollybus(target).updateSpot(
                address(uint160(uint256(rateId))),
                value_
            )
        {} catch {}
    }

    /// @notice Checks that the dispute operation can be performed by the Oracle given `nonce`.
    /// `proposeTimestamp` encoded in `nonce` has to be less than `disputeWindow`
    /// @param nonce Nonce of the current proposal [roundId, roundTimestamp, proposeTimestamp]
    /// @return canDispute True if dispute operation can be performed
    function canDispute(bytes32 nonce)
        public
        view
        override(OptimisticOracle)
        returns (bool)
    {
        return (sub(block.timestamp, uint64(uint256(nonce))) <= disputeWindow);
    }

    /// @notice Derives the nonce of a proposal from `data` and block.timestamp
    /// @param prevNonce Nonce of the previous proposal
    /// @param data Data of the current proposal [(roundId, roundTimestamp)]
    /// @return nonce [roundId, roundTimestamp, proposeTimestamp]
    /// @dev Reverts if the `disputeWindow` is still active
    /// Reverts if the current proposal is older than the previous proposal
    function encodeNonce(bytes32 prevNonce, bytes memory data)
        public
        view
        override(OptimisticOracle)
        returns (bytes32 nonce)
    {
        // decode `data` into `roundId` and `roundTimestamp`
        (uint80 roundId, uint64 roundTimestamp) = abi.decode(
            data,
            (uint80, uint64)
        );

        // skip the time window checks for the initial proposal
        if (prevNonce != 0) {
            // decode the round timestamp of the previous proposal from `nonce`
            (
                ,
                uint64 prevRoundTimestamp,
                uint64 prevProposeTimestamp
            ) = _decodeNonce(prevNonce);

            // revert if the current proposal is older than the previous proposal
            if (prevRoundTimestamp >= roundTimestamp) {
                revert OptimisticChainlinkOracle__encodeNonce_staleProposal();
            }

            // revert if prev. proposal is still within `disputeWindow`
            if (sub(block.timestamp, prevProposeTimestamp) <= disputeWindow) {
                revert OptimisticChainlinkOracle__encodeNonce_activeDisputeWindow();
            }
        }

        nonce = _encodeNonce(roundId, roundTimestamp, uint64(block.timestamp));
    }

    /// @notice Decodes `nonce` into `dataHash` and `proposeTimestamp`
    /// @param nonce Nonce of a proposal [roundId, roundTimestamp, proposeTimestamp]
    /// @return dataHash Proposal data contained in the nonce [(roundId, roundTimestamp)]
    /// @return proposeTimestamp Timestamp at which the proposal was created
    function decodeNonce(bytes32 nonce)
        public
        pure
        override(OptimisticOracle)
        returns (bytes32 dataHash, uint64 proposeTimestamp)
    {
        (
            uint80 roundId,
            uint64 roundTimestamp,
            uint64 proposeTimestamp_
        ) = _decodeNonce(nonce);

        dataHash = bytes32(
            (uint256(roundId) << 64) + (uint256(roundTimestamp))
        );
        proposeTimestamp = proposeTimestamp_;
    }

    /// @notice Encodes `roundId`, `roundTimestamp` and `proposeTimestamp` as `nonce`
    /// @param roundId Chainlink round id
    /// @param roundTimestamp Timestamp of the Chainlink round
    /// @param proposeTimestamp Timestamp at which the proposal was created
    /// @return nonce Nonce [roundId, roundTimestamp, proposeTimestamp]
    function _encodeNonce(
        uint80 roundId,
        uint64 roundTimestamp,
        uint64 proposeTimestamp
    ) internal pure returns (bytes32 nonce) {
        unchecked {
            nonce = bytes32(
                (uint256(roundId) << 128) +
                    (uint256(roundTimestamp) << 64) +
                    uint256(proposeTimestamp)
            );
        }
    }

    /// @notice Decodes the `roundId`, `roundTimestamp` and `proposeTimestamp` from `nonce`
    /// @param nonce bytes32 containing [roundId, roundTimestamp, proposeTimestamp]
    /// @return roundId Chainlink round id
    /// @return roundTimestamp Timestamp of the Chainlink round
    /// @return proposeTimestamp Timestamp at which the proposal was created

    function _decodeNonce(bytes32 nonce)
        internal
        pure
        returns (
            uint80 roundId,
            uint64 roundTimestamp,
            uint64 proposeTimestamp
        )
    {
        roundId = uint80(uint256(nonce >> 128));
        roundTimestamp = uint64(uint256(nonce >> 64));
        proposeTimestamp = uint64(uint256(nonce));
    }
}