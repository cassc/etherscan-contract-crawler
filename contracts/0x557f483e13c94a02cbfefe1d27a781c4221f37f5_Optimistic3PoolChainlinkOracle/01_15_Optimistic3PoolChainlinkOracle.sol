// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {sub, wdiv, min} from "fiat/core/utils/Math.sol";
import {ICollybus} from "fiat/interfaces/ICollybus.sol";

import {OptimisticOracle} from "./OptimisticOracle.sol";
import {IOptimistic3PoolChainlinkValue} from "./interfaces/IOptimistic3PoolChainlinkValue.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";

/// @title Optimistic3PoolChainlinkOracle
/// @notice Implementation of the OptimisticOracle for any 3-Token-Pool.
/// The oracle uses the chainlink feeds to fetch prices and
/// computes the minimum across the three assets.
/// Assumptions: If a Chainlink Aggregator is not working as intended (e.g. calls revert (excl. getRoundData))
/// then the methods `value` and `validate` and subsequently `dispute` will revert as well
contract Optimistic3PoolChainlinkOracle is
    OptimisticOracle,
    IOptimistic3PoolChainlinkValue
{
    /// ======== Custom Errors ======== ///

    error Optimistic3PoolChainlinkOracle__fetchLatestValue_invalidTimestamp();
    error Optimistic3PoolChainlinkOracle__encodeNonce_staleProposal();
    error Optimistic3PoolChainlinkOracle__encodeNonce_activeDisputeWindow();
    error Optimistic3PoolChainlinkOracle__push_inactiveRateId();
    error Optimistic3PoolChainlinkOracle__encodeNonce_invalidTimestamp();
    error Optimistic3PoolChainlinkOracle__validate_invalidData();

    /// ======== Storage ======== ///

    // @notice Chainlink Feeds
    address public immutable aggregatorFeed1;
    address public immutable aggregatorFeed2;
    address public immutable aggregatorFeed3;

    /// @notice A proposals validation result, as determined in `validate`
    enum ValidateResult {
        Success,
        InvalidRoundId,
        InvalidDataOrNonce,
        InvalidValue
    }

    /// ======== Events ======== ///

    /// @param target Address of target
    /// @param oracleType Unique identifier
    /// @param bondToken Address of the ERC20 token used by the bonding proposers
    /// @param bondSize Amount of `bondToken` a proposer has to bond in order to submit proposals for each `rateId`
    /// @param disputeWindow Period until a proposed value can not be disputed anymore [seconds]
    /// @param aggregatorFeed1_ Address of the first chainlink aggregator feed
    /// @param aggregatorFeed2_ Address of the second chainlink aggregator feed
    /// @param aggregatorFeed3_ Address of the third chainlink aggregator feed
    constructor(
        address target,
        bytes32 oracleType,
        IERC20 bondToken,
        uint256 bondSize,
        uint256 disputeWindow,
        address aggregatorFeed1_,
        address aggregatorFeed2_,
        address aggregatorFeed3_
    ) OptimisticOracle(target, oracleType, bondToken, bondSize, disputeWindow) {
        aggregatorFeed1 = aggregatorFeed1_;
        aggregatorFeed2 = aggregatorFeed2_;
        aggregatorFeed3 = aggregatorFeed3_;
    }

    /// ======== Chainlink Oracle Implementation ======== ///

    /// @notice Retrieves the latest spot price from each Chainlink feed
    /// and computes the minimum price.
    /// @dev Assumes that the Chainlink Aggregators work as intended
    /// @return value_ Minimum spot price across the three feeds [wad]
    /// @return data Latest round ids and round timestamps for the
    /// Chainlink feeds[uint80,uint64,uint80,uint64,uint80,uint64]
    function value()
        public
        view
        override
        returns (uint256 value_, bytes memory data)
    {
        (
            uint256 value1,
            uint80 roundId1,
            uint64 timestamp1
        ) = _fetchLatestValue(aggregatorFeed1);

        (
            uint256 value2,
            uint80 roundId2,
            uint64 timestamp2
        ) = _fetchLatestValue(aggregatorFeed2);

        (
            uint256 value3,
            uint80 roundId3,
            uint64 timestamp3
        ) = _fetchLatestValue(aggregatorFeed3);

        // compute the min value between the three feeds
        value_ = min(value1, min(value2, value3));

        data = abi.encode(
            roundId1,
            timestamp1,
            roundId2,
            timestamp2,
            roundId3,
            timestamp3
        );
    }

    /// ======== Proposal Management ======== ///

    /// @notice Validates `proposedValue` for given `nonce` via the corresponding Chainlink feeds
    /// @param proposedValue Value to be validated [wad]
    /// @param *rateId RateId (see target) of the proposal being validated
    /// @param nonce Nonce of the `proposedValue`
    /// @param data Data used to generate `nonce`
    /// @return result Result of the validation [ValidateResult]
    /// @return validValue The minimum value retrieved from the chainlink feeds [wad]
    /// @return validData Data corresponding to `validValue`
    function validate(
        uint256 proposedValue,
        bytes32, /*rateId*/
        bytes32 nonce,
        bytes memory data
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
        // validate the data length
        if (data.length != 192) {
            revert Optimistic3PoolChainlinkOracle__validate_invalidData();
        } else {
            (
                uint80 roundId1,
                uint64 timestamp1,
                uint80 roundId2,
                uint64 timestamp2,
                uint80 roundId3,
                uint64 timestamp3
            ) = abi.decode(
                    data,
                    (uint80, uint64, uint80, uint64, uint80, uint64)
                );

            // validate the feed 1 chainlink round
            validValue = _fetchAndValidate(
                aggregatorFeed1,
                roundId1,
                timestamp1
            );
            // validate the feed 2 chainlink round, skip if validation failed previously
            if (validValue != 0) {
                validValue = min(
                    validValue,
                    _fetchAndValidate(aggregatorFeed2, roundId2, timestamp2)
                );
            }
            // validate the feed 3 chainlink round, skip if validation failed previously
            if (validValue != 0) {
                validValue = min(
                    validValue,
                    _fetchAndValidate(aggregatorFeed3, roundId3, timestamp3)
                );
            }

            // `validValue` will be 0 if any feed fails the verification
            if (validValue == 0) {
                result = uint256(ValidateResult.InvalidRoundId);
            } else {
                // create the nonce from the validated data
                uint64 minTimestamp = uint64(
                    min(timestamp1, min(timestamp2, timestamp3))
                );

                bytes32 computedNonce = _encodeNonce(
                    keccak256(data),
                    minTimestamp,
                    uint64(uint256(nonce))
                );

                if (computedNonce != nonce) {
                    result = uint256(ValidateResult.InvalidDataOrNonce);
                } else {
                    result = (validValue == proposedValue)
                        ? uint256(ValidateResult.Success)
                        : uint256(ValidateResult.InvalidValue);
                }
            }
        }

        // retrieve fresh data in case the validation process failed
        if (result != uint256(ValidateResult.Success)) {
            (validValue, validData) = value();
        }
    }

    /// @notice Fetches the latest value from a Chainlink Aggregator feed
    /// @param feed Address of the Chainlink Aggregator
    /// @return value_ Latest value fetched [wad]
    /// @return roundId_ RoundId for `value_`
    /// @return roundTimestamp_ The timestamp at which the latest round was created
    function _fetchLatestValue(address feed)
        private
        view
        returns (
            uint256 value_,
            uint80 roundId_,
            uint64 roundTimestamp_
        )
    {
        (
            uint80 roundId,
            int256 feedValue,
            ,
            uint256 roundTimestamp,

        ) = AggregatorV3Interface(feed).latestRoundData();

        if (roundTimestamp > type(uint64).max)
            revert Optimistic3PoolChainlinkOracle__fetchLatestValue_invalidTimestamp();

        roundTimestamp_ = uint64(roundTimestamp);
        roundId_ = roundId;

        unchecked {
            // scale to WAD
            value_ = wdiv(
                uint256(feedValue),
                10**AggregatorV3Interface(feed).decimals()
            );
        }
    }

    /// @notice Fetches round value from a Chainlink Aggregator feed for a given `roundId`
    /// @param feed Address of the Chainlink Aggregator
    /// @param roundId RoundId of the Chainlink Aggregator to fetch round data for
    /// @param roundTimestamp The timestamp used to validate the round data
    /// @return roundValue Value fetched for the given `roundId` [wad]
    /// @dev Returns 0 if the round is not found or if `roundTimestamp` does not match the retrieved round timestamp
    function _fetchAndValidate(
        address feed,
        uint256 roundId,
        uint256 roundTimestamp
    ) private view returns (uint256 roundValue) {
        try AggregatorV3Interface(feed).getRoundData(uint80(roundId)) returns (
            uint80, /*roundId*/
            int256 roundValue_,
            uint256, /*startedAt*/
            uint256 roundTimestamp_,
            uint80 /*answeredInRound*/
        ) {
            // set the return value only if the timestamp is checked
            if (roundTimestamp_ == roundTimestamp) {
                unchecked {
                    // scale to WAD
                    roundValue = wdiv(
                        uint256(roundValue_),
                        10**AggregatorV3Interface(feed).decimals()
                    );
                }
            }
        } catch {}
    }

    /// @notice Pushes a value directly to target by computing it on-chain
    /// without going through the shift / dispute process
    /// @dev Overwrites the current queued proposal with the blank (initial) proposal
    /// @param rateId RateId (see target)
    function push(bytes32 rateId) public override(OptimisticOracle) {
        if (!activeRateIds[rateId])
            revert Optimistic3PoolChainlinkOracle__push_inactiveRateId();

        // fetch the latest value from the Chainlink Aggregators
        (uint256 value1, , uint64 timestamp1) = _fetchLatestValue(
            aggregatorFeed1
        );
        (uint256 value2, , uint64 timestamp2) = _fetchLatestValue(
            aggregatorFeed2
        );
        (uint256 value3, , uint64 timestamp3) = _fetchLatestValue(
            aggregatorFeed3
        );

        // compute the min value
        uint256 value_ = min(value1, min(value2, value3));

        // compute the min round timestamp
        uint64 minTimestamp = uint64(
            min(timestamp1, min(timestamp2, timestamp3))
        );

        bytes32 nonce = _encodeNonce(0, minTimestamp, 0);
        // reset the current proposal
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
    /// @param nonce Nonce of the current proposal
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
    /// @param data Encoded round ids and round timestamps for the
    /// chainlink rounds [uint80,uint64,uint80,uint64,uint80,uint64]
    /// @return nonce Nonce of the current proposal
    /// @dev Reverts if the `disputeWindow` is still active
    /// Reverts if the current proposal is older than the previous proposal
    function encodeNonce(bytes32 prevNonce, bytes memory data)
        public
        view
        override(OptimisticOracle)
        returns (bytes32 nonce)
    {
        // decode the timestamp of each round, must revert if data cannot be decoded
        (
            ,
            uint64 roundTimestamp1,
            ,
            uint64 roundTimestamp2,
            ,
            uint64 roundTimestamp3
        ) = abi.decode(data, (uint80, uint64, uint80, uint64, uint80, uint64));

        // compute the min between the three timestamps
        uint64 minTimestamp = uint64(
            min(roundTimestamp1, min(roundTimestamp2, roundTimestamp3))
        );

        // skip the time window checks for the initial proposal
        if (prevNonce != 0) {
            // decode the round timestamp of the previous proposal from `nonce`
            (
                ,
                uint64 prevTimestamp,
                uint64 prevProposeTimestamp
            ) = _decodeNonce(prevNonce);

            // revert if the current proposal is older than the previous proposal
            if (prevTimestamp >= uint64(minTimestamp)) {
                revert Optimistic3PoolChainlinkOracle__encodeNonce_staleProposal();
            }

            // revert if prev. proposal is still within `disputeWindow`
            if (sub(block.timestamp, prevProposeTimestamp) <= disputeWindow) {
                revert Optimistic3PoolChainlinkOracle__encodeNonce_activeDisputeWindow();
            }
        }

        // create the nonce
        nonce = _encodeNonce(
            keccak256(data),
            uint64(minTimestamp),
            uint64(block.timestamp)
        );
    }

    /// @notice Decodes `nonce` into `dataHash` and `proposeTimestamp`
    /// @param nonce Nonce of a proposal
    /// @return noncePrefix The prefix of nonce [dataHash,round timestamp]
    /// @return proposeTimestamp Timestamp at which the proposal was created
    function decodeNonce(bytes32 nonce)
        public
        pure
        override(OptimisticOracle)
        returns (bytes32 noncePrefix, uint64 proposeTimestamp)
    {
        (
            bytes32 dataHash,
            uint64 roundTimestamp,
            uint64 proposeTimestamp_
        ) = _decodeNonce(nonce);
        noncePrefix = bytes32(
            (uint256(dataHash << 128) + uint256(roundTimestamp)) << 64
        );
        proposeTimestamp = proposeTimestamp_;
    }

    /// @notice Encodes `dataHash`, `roundTimestamp` and `proposeTimestamp` as `nonce`
    /// @param dataHash The keccak hash of the proposal data
    /// @param roundTimestamp Timestamp of the Chainlink round
    /// @param proposeTimestamp Timestamp at which the proposal was created
    /// @return nonce Nonce [dataHash, roundTimestamp, proposeTimestamp]
    function _encodeNonce(
        bytes32 dataHash,
        uint64 roundTimestamp,
        uint64 proposeTimestamp
    ) internal pure returns (bytes32 nonce) {
        unchecked {
            nonce = bytes32(
                (uint256(dataHash) << 128) +
                    (uint256(roundTimestamp) << 64) +
                    uint256(proposeTimestamp)
            );
        }
    }

    /// @notice Decodes the `dataHash`, `roundTimestamp` and `proposeTimestamp` from `nonce`
    /// @param nonce bytes32 containing [roundId, roundTimestamp, proposeTimestamp]
    /// @return dataHash Hash of the proposal data contained in the nonce
    /// @return roundTimestamp Timestamp of the Chainlink round
    /// @return proposeTimestamp Timestamp at which the proposal was created

    function _decodeNonce(bytes32 nonce)
        internal
        pure
        returns (
            bytes32 dataHash,
            uint64 roundTimestamp,
            uint64 proposeTimestamp
        )
    {
        dataHash = bytes32(uint256(nonce >> 128));
        roundTimestamp = uint64(uint256(nonce >> 64));
        proposeTimestamp = uint64(uint256(nonce));
    }
}