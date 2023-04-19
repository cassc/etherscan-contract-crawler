// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

import { Ownable } from  "@openzeppelin/contracts/access/Ownable.sol";

/** @notice YieldData keeps track of historical average yields on a periodic
    basis. It uses this data to return the overall average yield for a range
    of time in the `yieldPerTokenPerSlock` method. This method is O(N) on the
    number of epochs recorded. Therefore, to prevent excessive gas costs, the
    interval should be set such that N does not exceed around a thousand. An
    interval of 10 days will stay below this limit for a few decades. Keep in
    mind, though, that a larger interval reduces accuracy.
*/
contract YieldData is Ownable {
    uint256 public constant PRECISION_FACTOR = 10**18;

    address public writer;
    uint128 public immutable interval;

    struct Epoch {
        uint256 tokens;
        uint256 yield;
        uint256 yieldPerToken;
        uint128 blockTimestamp;
        uint128 epochSeconds;
    }
    Epoch[] public epochs;
    uint128 public epochIndex;

    /// @notice Create a YieldData.
    /// @param interval_ Minimum size in seconds of each epoch.
    constructor(uint128 interval_) {
        interval = interval_;
    }

    /// @notice Set the writer.
    /// @param writer_ The new writer.
    function setWriter(address writer_) external onlyOwner {
        require(writer_ != address(0), "YD: zero address");
        writer = writer_;
    }

    /// @notice Check if data is empty.
    /// @return True if the data is empty.
    function isEmpty() external view returns (bool) {
        return epochs.length == 0;
    }

    /// @notice Get the current epoch.
    /// @return The current epoch.
    function current() external view returns (Epoch memory) {
        return epochs[epochIndex];
    }

    function _record(uint256 tokens, uint256 yield) internal view returns
        (Epoch memory epochPush, Epoch memory epochSet) {

        if (epochs.length == 0) {
            epochPush = Epoch({
                blockTimestamp: uint128(block.timestamp),
                epochSeconds: 0,
                tokens: tokens,
                yield: yield,
                yieldPerToken: 0 });
        } else {
            Epoch memory c = epochs[epochIndex];

            uint128 epochSeconds = uint128(block.timestamp) - c.blockTimestamp - c.epochSeconds;
            uint256 delta = (yield - c.yield);

            c.yieldPerToken += c.tokens == 0 ? 0 : delta * PRECISION_FACTOR / c.tokens;
            c.epochSeconds += epochSeconds;

            if (c.epochSeconds >= interval) {
                epochPush = Epoch({
                    blockTimestamp: uint128(block.timestamp),
                    epochSeconds: 0,
                    tokens: tokens,
                    yield: yield,
                    yieldPerToken: 0 });
            } else {
                c.tokens = tokens;
            }

            c.yield = yield;
            epochSet = c;
        }
    }

    /// @notice Record new data.
    /// @param tokens Amount of generating tokens for this data point.
    /// @param yield Amount of yield generated for this data point. Cumulative and monotonically increasing.
    function record(uint256 tokens, uint256 yield) external {
        require(msg.sender == writer, "YD: only writer");

        (Epoch memory epochPush, Epoch memory epochSet) = _record(tokens, yield);

        if (epochSet.blockTimestamp != 0) {
            epochs[epochIndex] = epochSet;
        }
        if (epochPush.blockTimestamp != 0) {
            epochs.push(epochPush);
            epochIndex = uint128(epochs.length) - 1;
        }
    }

    function _find(uint128 blockTimestamp) internal view returns (uint256) {
        require(epochs.length > 0, "no epochs");
        if (blockTimestamp >= epochs[epochIndex].blockTimestamp) return epochIndex;
        if (blockTimestamp <= epochs[0].blockTimestamp) return 0;

        uint256 i = epochs.length / 2;
        uint256 start = 0;
        uint256 end = epochs.length;
        while (true) {
            uint128 bn = epochs[i].blockTimestamp;
            if (blockTimestamp >= bn &&
                (i + 1 > epochIndex || blockTimestamp < epochs[i + 1].blockTimestamp)) {
                return i;
            }

            if (blockTimestamp > bn) {
                start = i + 1;
            } else {
                end = i;
            }
            i = (start + end) / 2;
        }

        return epochIndex;
    }

    /// @notice Compute the yield per token per second for a time range. The first and final epoch in the time range are prorated, and therefore the resulting value is an approximation.
    /// @param start Timestamp indicating the start of the time range.
    /// @param end Timestmap indicating the end of the time range.
    /// @param tokens Optional, the amount of tokens locked. Can be 0.
    /// @param tokens Optional, the amount of cumulative. Can be 0.
    /// @return Amount of yield per `PRECISION_FACTOR` amount of tokens per second.
    function yieldPerTokenPerSecond(uint128 start, uint128 end, uint256 tokens, uint256 yield) public view returns (uint256) {
        if (start == end) return 0;
        if (start == uint128(block.timestamp)) return 0;

        require(start < end, "YD: start must precede end");
        require(end <= uint128(block.timestamp), "YD: end must be in the past or current");
        require(start < uint128(block.timestamp), "YD: start must be in the past");

        uint256 index = _find(start);
        uint256 yieldPerToken;
        uint256 numSeconds;

        Epoch memory epochPush;
        Epoch memory epochSet;
        if (yield != 0) (epochPush, epochSet) = _record(tokens, yield);
        uint128 maxIndex = epochPush.blockTimestamp == 0 ? epochIndex : epochIndex + 1;

        while (true) {
            if (index > maxIndex) break;
            Epoch memory epoch;
            if (epochPush.blockTimestamp != 0 && index == maxIndex) {
                epoch = epochPush;
            } else if (epochSet.blockTimestamp != 0 && index == epochIndex) {
                epoch = epochSet;
            } else {
                epoch = epochs[index];
            }

            ++index;

            uint256 epochSeconds = epoch.epochSeconds;
            if (epochSeconds == 0) break;
            if (end < epoch.blockTimestamp) break;

            if (start > epoch.blockTimestamp) {
                epochSeconds -= start - epoch.blockTimestamp;
            }
            if (end < epoch.blockTimestamp + epoch.epochSeconds) {
                epochSeconds -= epoch.blockTimestamp + epoch.epochSeconds - end;
            }

            uint256 incr = (epochSeconds * epoch.yieldPerToken) / epoch.epochSeconds;

            yieldPerToken += incr;
            numSeconds += epochSeconds;

            if (end < epoch.blockTimestamp + epoch.epochSeconds) break;
        }

        if (numSeconds == 0) return 0;

        return yieldPerToken / numSeconds;
    }
}