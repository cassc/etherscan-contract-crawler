pragma solidity 0.8.2;

library TwapLogic {
    enum TwapCalcOption {
        RESERVE_ASSET,
        INPUT_ASSET
    }

    struct TwapPriceCalcParams {
        TwapCalcOption opt;
        uint256 snapshotIndex;
    }
    struct ReserveSnapshot {
        uint128 pip;
        uint64 timestamp;
        uint64 blockNumber;
    }

    function add(ReserveSnapshot[] storage reserveSnapshots, uint128 pip, uint64 timestamp, uint64 blockNumber) internal {
        reserveSnapshots.push(ReserveSnapshot({
            pip: pip,
            timestamp: timestamp,
            blockNumber: blockNumber
        }));
    }

    function addReserveSnapshot(ReserveSnapshot[] storage reserveSnapshots, uint128 pip) internal {
        uint64 currentBlock = uint64(block.number);
        ReserveSnapshot memory latestSnapshot = reserveSnapshots[
            reserveSnapshots.length - 1
        ];
        if (currentBlock == latestSnapshot.blockNumber) {
            reserveSnapshots[reserveSnapshots.length - 1].pip = pip;
        } else {
            reserveSnapshots.push(
                ReserveSnapshot(pip, _now(), currentBlock)
            );
        }
    }

    function getReserveTwapPrice(ReserveSnapshot[] storage reserveSnapshots, uint256 _intervalInSeconds)
    internal
    view
    returns (uint256)
    {
        TwapPriceCalcParams memory params;
        // Can remove this line
        params.opt = TwapCalcOption.RESERVE_ASSET;
        params.snapshotIndex = reserveSnapshots.length - 1;
        return calcTwap(reserveSnapshots, params, _intervalInSeconds);
    }

    function calcTwap(
        ReserveSnapshot[] storage reserveSnapshots,
        TwapPriceCalcParams memory _params,
        uint256 _intervalInSeconds
    ) public view returns (uint256) {
        uint256 currentPrice = _getPriceWithSpecificSnapshot(reserveSnapshots, _params);
        if (_intervalInSeconds == 0) {
            return currentPrice;
        }

        uint256 baseTimestamp = _now() - _intervalInSeconds;
        ReserveSnapshot memory currentSnapshot = reserveSnapshots[
            _params.snapshotIndex
        ];
        // return the latest snapshot price directly
        // if only one snapshot or the timestamp of latest snapshot is earlier than asking for
        if (
            reserveSnapshots.length == 1 ||
            currentSnapshot.timestamp <= baseTimestamp
        ) {
            return currentPrice;
        }

        uint256 previousTimestamp = currentSnapshot.timestamp;
        // period same as cumulativeTime
        uint256 period = _now() - previousTimestamp;
        uint256 weightedPrice = currentPrice * period;
        while (true) {
            // if snapshot history is too short
            if (_params.snapshotIndex == 0) {
                return weightedPrice / period;
            }

            _params.snapshotIndex = _params.snapshotIndex - 1;
            currentSnapshot = reserveSnapshots[_params.snapshotIndex];
            currentPrice = _getPriceWithSpecificSnapshot(reserveSnapshots, _params);

            // check if current snapshot timestamp is earlier than target timestamp
            if (currentSnapshot.timestamp <= baseTimestamp) {
                // weighted time period will be (target timestamp - previous timestamp). For example,
                // now is 1000, _intervalInSeconds is 100, then target timestamp is 900. If timestamp of current snapshot is 970,
                // and timestamp of NEXT snapshot is 880, then the weighted time period will be (970 - 900) = 70,
                // instead of (970 - 880)
                weightedPrice =
                weightedPrice +
                (currentPrice * (previousTimestamp - baseTimestamp));
                break;
            }

            uint256 timeFraction = previousTimestamp -
            currentSnapshot.timestamp;
            weightedPrice = weightedPrice + (currentPrice * timeFraction);
            period = period + timeFraction;
            previousTimestamp = currentSnapshot.timestamp;
        }
        return weightedPrice / _intervalInSeconds;
    }

    function _now() private view returns (uint64) {
        return uint64(block.timestamp);
    }

    function _getPriceWithSpecificSnapshot(ReserveSnapshot[] storage reserveSnapshots, TwapPriceCalcParams memory _params)
        internal
        view
        returns (uint256)
    {
        return (reserveSnapshots[_params.snapshotIndex].pip);
    }
}