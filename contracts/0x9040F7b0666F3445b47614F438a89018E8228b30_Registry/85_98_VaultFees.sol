// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { VaultFeesStorage } from './VaultFeesStorage.sol';
import { Constants } from '../lib/Constants.sol';

contract VaultFees {
    event FeeIncreaseAnnounced(uint streamingFee, uint performanceFee);
    event FeeIncreaseCommitted(uint streamingFee, uint performanceFee);
    event FeeIncreaseRenounced();

    uint internal constant _PROTOCOL_FEE_BASIS_POINTS = 2000; // 20% of ManagerFees
    uint internal constant _STEAMING_FEE_DURATION = 365 days;

    uint internal constant _MAX_STREAMING_FEE_BASIS_POINTS = 300; // 3%
    uint internal constant _MAX_STREAMING_FEE_BASIS_POINTS_STEP = 50; // 0.5%
    uint internal constant _MAX_PERFORMANCE_FEE_BASIS_POINTS = 4000; // 40%
    uint internal constant _MAX_PERFORMANCE_FEE_BASIS_POINTS_STEP = 1000; // 10%
    uint internal constant _FEE_ANNOUNCE_WINDOW = 30 days;

    function initialize(
        uint _managerStreamingFeeBasisPoints,
        uint _managerPerformanceFeeBasisPoints
    ) internal {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        l.managerStreamingFee = _managerStreamingFeeBasisPoints;
        l.managerPerformanceFee = _managerPerformanceFeeBasisPoints;
    }

    function _managerPerformanceFee() internal view returns (uint) {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        return l.managerPerformanceFee;
    }

    function _managerStreamingFee() internal view returns (uint) {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        return l.managerStreamingFee;
    }

    function _announcedManagerPerformanceFee() internal view returns (uint) {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        return l.announcedManagerPerformanceFee;
    }

    function _announcedManagerStreamingFee() internal view returns (uint) {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();
        return l.announcedManagerStreamingFee;
    }

    function _announcedFeeIncreaseTimestamp() internal view returns (uint) {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        return l.announcedFeeIncreaseTimestamp;
    }

    function _streamingFee(
        uint fee,
        uint discount,
        uint lastFeeTime,
        uint totalShares,
        uint timeNow
    ) internal pure returns (uint tokensOwed) {
        if (lastFeeTime >= timeNow) {
            return 0;
        }

        uint discountAdjustment = Constants.BASIS_POINTS_DIVISOR - discount;
        uint timeSinceLastFee = timeNow - lastFeeTime;
        tokensOwed =
            (totalShares * fee * timeSinceLastFee * discountAdjustment) /
            _STEAMING_FEE_DURATION /
            Constants.BASIS_POINTS_DIVISOR /
            Constants.BASIS_POINTS_DIVISOR;
    }

    function _performanceFee(
        uint fee,
        uint discount,
        uint totalShares,
        uint tokenPriceStart,
        uint tokenPriceFinish
    ) internal pure returns (uint tokensOwed) {
        if (tokenPriceFinish <= tokenPriceStart) {
            return 0;
        }

        uint discountAdjustment = Constants.BASIS_POINTS_DIVISOR - discount;
        uint priceIncrease = tokenPriceFinish - (tokenPriceStart);
        tokensOwed =
            (priceIncrease * fee * totalShares * discountAdjustment) /
            tokenPriceStart /
            Constants.BASIS_POINTS_DIVISOR /
            Constants.BASIS_POINTS_DIVISOR;
    }

    function _protocolFee(uint managerFees) internal pure returns (uint) {
        return
            (managerFees * _PROTOCOL_FEE_BASIS_POINTS) /
            Constants.BASIS_POINTS_DIVISOR;
    }

    function _announceFeeIncrease(
        uint256 newStreamingFee,
        uint256 newPerformanceFee
    ) internal {
        require(
            newStreamingFee <= _MAX_STREAMING_FEE_BASIS_POINTS,
            'streamingFee to high'
        );

        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        require(
            newStreamingFee <=
                l.managerStreamingFee + _MAX_STREAMING_FEE_BASIS_POINTS_STEP,
            'streamingFee step exceeded'
        );
        require(
            newPerformanceFee <= _MAX_PERFORMANCE_FEE_BASIS_POINTS,
            'performanceFee to high'
        );
        require(
            newPerformanceFee <=
                l.managerPerformanceFee +
                    _MAX_PERFORMANCE_FEE_BASIS_POINTS_STEP,
            'performanceFee step exceeded'
        );

        l.announcedFeeIncreaseTimestamp = block.timestamp;
        l.announcedManagerStreamingFee = newStreamingFee;
        l.announcedManagerPerformanceFee = newPerformanceFee;
        emit FeeIncreaseAnnounced(newStreamingFee, newPerformanceFee);
    }

    function _renounceFeeIncrease() internal {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        require(
            l.announcedFeeIncreaseTimestamp != 0,
            'no fee increase announced'
        );

        l.announcedFeeIncreaseTimestamp = 0;
        l.announcedManagerStreamingFee = 0;
        l.announcedManagerPerformanceFee = 0;

        emit FeeIncreaseRenounced();
    }

    function _commitFeeIncrease() internal {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        require(
            l.announcedFeeIncreaseTimestamp != 0,
            'no fee increase announced'
        );
        require(
            block.timestamp >=
                l.announcedFeeIncreaseTimestamp + _FEE_ANNOUNCE_WINDOW,
            'fee delay active'
        );

        l.managerStreamingFee = l.announcedManagerStreamingFee;
        l.managerPerformanceFee = l.announcedManagerPerformanceFee;

        l.announcedFeeIncreaseTimestamp = 0;
        l.announcedManagerStreamingFee = 0;
        l.announcedManagerPerformanceFee = 0;

        emit FeeIncreaseCommitted(
            l.managerStreamingFee,
            l.managerPerformanceFee
        );
    }
}