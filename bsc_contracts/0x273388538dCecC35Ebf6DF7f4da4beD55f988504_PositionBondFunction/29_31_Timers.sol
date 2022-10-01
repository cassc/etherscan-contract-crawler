pragma solidity ^0.8.9;

type Timestamp is uint64;

library Timers {
    function unwrap(Timestamp timer) internal pure returns (uint64) {
        return Timestamp.unwrap(timer);
    }

    function isUnset(Timestamp timer) internal pure returns (bool) {
        return unwrap(timer) == 0;
    }

    function isStarted(Timestamp timer) internal pure returns (bool) {
        return unwrap(timer) > 0;
    }

    function passed(Timestamp timer, uint256 _now)
        internal
        pure
        returns (bool)
    {
        return unwrap(timer) < _now && unwrap(timer) > 0;
    }

    function isPending(Timestamp timer) internal view returns (bool) {
        return unwrap(timer) > block.timestamp;
    }

    function isExpired(Timestamp timer) internal view returns (bool) {
        return isStarted(timer) && unwrap(timer) <= block.timestamp;
    }
}