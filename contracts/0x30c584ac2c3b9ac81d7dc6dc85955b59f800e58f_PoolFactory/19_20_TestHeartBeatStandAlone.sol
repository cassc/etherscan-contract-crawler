// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

import "./IChainLink.sol";

contract HeartbeatStandAlone{

    constructor(){
    }

    mapping(address => uint256) public chainLinkHeartBeat;

    uint80 public constant MAX_ROUND_COUNT = 50;

    function getLatestAggregatorRoundId(
        address _feed
    )
        public
        view
        returns (uint80)
    {
        (   uint80 roundId,
            ,
            ,
            ,
        ) = IChainLink(_feed).latestRoundData();

        return uint64(roundId);
    }

    function getRoundIdByByteShift(
        uint16 _phaseId,
        uint80 _aggregatorRoundId
    )
        public
        pure
        returns (uint80)
    {
        return uint80(uint256(_phaseId) << 64 | _aggregatorRoundId);
    }

    function recalibratePreview(
        address _feed
    )
        public
        view
        returns (uint256)
    {
        uint80 latestAggregatorRoundId = getLatestAggregatorRoundId(
            _feed
        );

        uint80 iterationCount = _getIterationCount(
            latestAggregatorRoundId
        );

        if (iterationCount < 2) {
            revert("LiquidRouter: SMALL_SAMPLE");
        }

        uint16 phaseId = IChainLink(_feed).phaseId();
        uint256 latestTimestamp = _getRoundTimestamp(
            _feed,
            phaseId,
            latestAggregatorRoundId
        );

        uint256 currentDiff;
        uint256 currentBiggest;
        uint256 currentSecondBiggest;

        for (uint80 i = 1; i < iterationCount; i++) {

            uint256 currentTimestamp = _getRoundTimestamp(
                _feed,
                phaseId,
                latestAggregatorRoundId - i
            );

            currentDiff = latestTimestamp
                - currentTimestamp;

            latestTimestamp = currentTimestamp;

            if (currentDiff >= currentBiggest) {
                currentSecondBiggest = currentBiggest;
                currentBiggest = currentDiff;
            } else if (currentDiff > currentSecondBiggest && currentDiff < currentBiggest) {
                currentSecondBiggest = currentDiff;
            }
        }

        return currentSecondBiggest;
    }

    function _getIterationCount(
        uint80 _latestAggregatorRoundId
    )
        internal
        pure
        returns (uint80)
    {
        return _latestAggregatorRoundId > MAX_ROUND_COUNT
            ? MAX_ROUND_COUNT
            : _latestAggregatorRoundId;
    }

    function _getRoundTimestamp(
        address _feed,
        uint16 _phaseId,
        uint80 _aggregatorRoundId
    )
        internal
        view
        returns (uint256)
    {
        (
            ,
            ,
            ,
            uint256 timestamp,
        ) = IChainLink(_feed).getRoundData(
            getRoundIdByByteShift(
                _phaseId,
                _aggregatorRoundId
            )
        );

        return timestamp;
    }

    function recalibrate(
        address _feed
    )
        external
    {
        chainLinkHeartBeat[_feed] = recalibratePreview(_feed);
    }
}
