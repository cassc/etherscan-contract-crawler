// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

/// @notice A stream receiver
struct StreamReceiver {
    /// @notice The account ID.
    uint256 accountId;
    /// @notice The stream configuration.
    StreamConfig config;
}

/// @notice The sender streams history entry, used when squeezing streams.
struct StreamsHistory {
    /// @notice Streams receivers list hash, see `_hashStreams`.
    /// If it's non-zero, `receivers` must be empty.
    bytes32 streamsHash;
    /// @notice The streams receivers. If it's non-empty, `streamsHash` must be `0`.
    /// If it's empty, this history entry will be skipped when squeezing streams
    /// and `streamsHash` will be used when verifying the streams history validity.
    /// Skipping a history entry allows cutting gas usage on analysis
    /// of parts of the streams history which are not worth squeezing.
    /// The hash of an empty receivers list is `0`, so when the sender updates
    /// their receivers list to be empty, the new `StreamsHistory` entry will have
    /// both the `streamsHash` equal to `0` and the `receivers` empty making it always skipped.
    /// This is fine, because there can't be any funds to squeeze from that entry anyway.
    StreamReceiver[] receivers;
    /// @notice The time when streams have been configured
    uint32 updateTime;
    /// @notice The maximum end time of streaming.
    uint32 maxEnd;
}

/// @notice Describes a streams configuration.
/// It's a 256-bit integer constructed by concatenating the configuration parameters:
/// `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`.
/// `streamId` is an arbitrary number used to identify a stream.
/// It's a part of the configuration but the protocol doesn't use it.
/// `amtPerSec` is the amount per second being streamed. Must never be zero.
/// It must have additional `Streams._AMT_PER_SEC_EXTRA_DECIMALS` decimals and can have fractions.
/// To achieve that its value must be multiplied by `Streams._AMT_PER_SEC_MULTIPLIER`.
/// `start` is the timestamp when streaming should start.
/// If zero, use the timestamp when the stream is configured.
/// `duration` is the duration of streaming.
/// If zero, stream until balance runs out.
type StreamConfig is uint256;

using StreamConfigImpl for StreamConfig global;

library StreamConfigImpl {
    /// @notice Create a new StreamConfig.
    /// @param streamId_ An arbitrary number used to identify a stream.
    /// It's a part of the configuration but the protocol doesn't use it.
    /// @param amtPerSec_ The amount per second being streamed. Must never be zero.
    /// It must have additional `Streams._AMT_PER_SEC_EXTRA_DECIMALS`
    /// decimals and can have fractions.
    /// To achieve that the passed value must be multiplied by `Streams._AMT_PER_SEC_MULTIPLIER`.
    /// @param start_ The timestamp when streaming should start.
    /// If zero, use the timestamp when the stream is configured.
    /// @param duration_ The duration of streaming. If zero, stream until the balance runs out.
    function create(uint32 streamId_, uint160 amtPerSec_, uint32 start_, uint32 duration_)
        internal
        pure
        returns (StreamConfig)
    {
        // By assignment we get `config` value:
        // `zeros (224 bits) | streamId (32 bits)`
        uint256 config = streamId_;
        // By bit shifting we get `config` value:
        // `zeros (64 bits) | streamId (32 bits) | zeros (160 bits)`
        // By bit masking we get `config` value:
        // `zeros (64 bits) | streamId (32 bits) | amtPerSec (160 bits)`
        config = (config << 160) | amtPerSec_;
        // By bit shifting we get `config` value:
        // `zeros (32 bits) | streamId (32 bits) | amtPerSec (160 bits) | zeros (32 bits)`
        // By bit masking we get `config` value:
        // `zeros (32 bits) | streamId (32 bits) | amtPerSec (160 bits) | start (32 bits)`
        config = (config << 32) | start_;
        // By bit shifting we get `config` value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | zeros (32 bits)`
        // By bit masking we get `config` value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`
        config = (config << 32) | duration_;
        return StreamConfig.wrap(config);
    }

    /// @notice Extracts streamId from a `StreamConfig`
    function streamId(StreamConfig config) internal pure returns (uint32) {
        // `config` has value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`
        // By bit shifting we get value:
        // `zeros (224 bits) | streamId (32 bits)`
        // By casting down we get value:
        // `streamId (32 bits)`
        return uint32(StreamConfig.unwrap(config) >> 224);
    }

    /// @notice Extracts amtPerSec from a `StreamConfig`
    function amtPerSec(StreamConfig config) internal pure returns (uint160) {
        // `config` has value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`
        // By bit shifting we get value:
        // `zeros (64 bits) | streamId (32 bits) | amtPerSec (160 bits)`
        // By casting down we get value:
        // `amtPerSec (160 bits)`
        return uint160(StreamConfig.unwrap(config) >> 64);
    }

    /// @notice Extracts start from a `StreamConfig`
    function start(StreamConfig config) internal pure returns (uint32) {
        // `config` has value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`
        // By bit shifting we get value:
        // `zeros (32 bits) | streamId (32 bits) | amtPerSec (160 bits) | start (32 bits)`
        // By casting down we get value:
        // `start (32 bits)`
        return uint32(StreamConfig.unwrap(config) >> 32);
    }

    /// @notice Extracts duration from a `StreamConfig`
    function duration(StreamConfig config) internal pure returns (uint32) {
        // `config` has value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`
        // By casting down we get value:
        // `duration (32 bits)`
        return uint32(StreamConfig.unwrap(config));
    }

    /// @notice Compares two `StreamConfig`s.
    /// First compares `streamId`s, then `amtPerSec`s, then `start`s and finally `duration`s.
    /// @return isLower True if `config` is strictly lower than `otherConfig`.
    function lt(StreamConfig config, StreamConfig otherConfig)
        internal
        pure
        returns (bool isLower)
    {
        // Both configs have value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`
        // Comparing them as integers is equivalent to comparing their fields from left to right.
        return StreamConfig.unwrap(config) < StreamConfig.unwrap(otherConfig);
    }
}

/// @notice Streams can keep track of at most `type(int128).max`
/// which is `2 ^ 127 - 1` units of each ERC-20 token.
/// It's up to the caller to guarantee that this limit is never exceeded,
/// failing to do so may result in a total protocol collapse.
abstract contract Streams {
    /// @notice Maximum number of streams receivers of a single account.
    /// Limits cost of changes in streams configuration.
    uint256 internal constant _MAX_STREAMS_RECEIVERS = 100;
    /// @notice The additional decimals for all amtPerSec values.
    uint8 internal constant _AMT_PER_SEC_EXTRA_DECIMALS = 9;
    /// @notice The multiplier for all amtPerSec values. It's `10 ** _AMT_PER_SEC_EXTRA_DECIMALS`.
    uint160 internal constant _AMT_PER_SEC_MULTIPLIER = 1_000_000_000;
    /// @notice The amount the contract can keep track of each ERC-20 token.
    uint128 internal constant _MAX_STREAMS_BALANCE = uint128(type(int128).max);
    /// @notice On every timestamp `T`, which is a multiple of `cycleSecs`, the receivers
    /// gain access to streams received during `T - cycleSecs` to `T - 1`.
    /// Always higher than 1.
    // slither-disable-next-line naming-convention
    uint32 internal immutable _cycleSecs;
    /// @notice The minimum amtPerSec of a stream. It's 1 token per cycle.
    // slither-disable-next-line naming-convention
    uint160 internal immutable _minAmtPerSec;
    /// @notice The storage slot holding a single `StreamsStorage` structure.
    bytes32 private immutable _streamsStorageSlot;

    /// @notice Emitted when the streams configuration of an account is updated.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// @param receiversHash The streams receivers list hash
    /// @param streamsHistoryHash The streams history hash that was valid right before the update.
    /// @param balance The account's streams balance. These funds will be streamed to the receivers.
    /// @param maxEnd The maximum end time of streaming, when funds run out.
    /// If funds run out after the timestamp `type(uint32).max`, it's set to `type(uint32).max`.
    /// If the balance is 0 or there are no receivers, it's set to the current timestamp.
    event StreamsSet(
        uint256 indexed accountId,
        IERC20 indexed erc20,
        bytes32 indexed receiversHash,
        bytes32 streamsHistoryHash,
        uint128 balance,
        uint32 maxEnd
    );

    /// @notice Emitted when an account is seen in a streams receivers list.
    /// @param receiversHash The streams receivers list hash
    /// @param accountId The account ID.
    /// @param config The streams configuration.
    event StreamReceiverSeen(
        bytes32 indexed receiversHash, uint256 indexed accountId, StreamConfig config
    );

    /// @notice Emitted when streams are received.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// @param amt The received amount.
    /// @param receivableCycles The number of cycles which still can be received.
    event ReceivedStreams(
        uint256 indexed accountId, IERC20 indexed erc20, uint128 amt, uint32 receivableCycles
    );

    /// @notice Emitted when streams are squeezed.
    /// @param accountId The squeezing account ID.
    /// @param erc20 The used ERC-20 token.
    /// @param senderId The ID of the streaming account from whom funds are squeezed.
    /// @param amt The squeezed amount.
    /// @param streamsHistoryHashes The history hashes of all squeezed streams history entries.
    /// Each history hash matches `streamsHistoryHash` emitted in its `StreamsSet`
    /// when the squeezed streams configuration was set.
    /// Sorted in the oldest streams configuration to the newest.
    event SqueezedStreams(
        uint256 indexed accountId,
        IERC20 indexed erc20,
        uint256 indexed senderId,
        uint128 amt,
        bytes32[] streamsHistoryHashes
    );

    struct StreamsStorage {
        /// @notice Account streams states.
        mapping(IERC20 erc20 => mapping(uint256 accountId => StreamsState)) states;
    }

    struct StreamsState {
        /// @notice The streams history hash, see `_hashStreamsHistory`.
        bytes32 streamsHistoryHash;
        /// @notice The next squeezable timestamps.
        /// Each `N`th element of the array is the next squeezable timestamp
        /// of the `N`th sender's streams configuration in effect in the current cycle.
        mapping(uint256 accountId => uint32[2 ** 32]) nextSqueezed;
        /// @notice The streams receivers list hash, see `_hashStreams`.
        bytes32 streamsHash;
        /// @notice The next cycle to be received
        uint32 nextReceivableCycle;
        /// @notice The time when streams have been configured for the last time.
        uint32 updateTime;
        /// @notice The maximum end time of streaming.
        uint32 maxEnd;
        /// @notice The balance when streams have been configured for the last time.
        uint128 balance;
        /// @notice The number of streams configurations seen in the current cycle
        uint32 currCycleConfigs;
        /// @notice The changes of received amounts on specific cycle.
        /// The keys are cycles, each cycle `C` becomes receivable on timestamp `C * cycleSecs`.
        /// Values for cycles before `nextReceivableCycle` are guaranteed to be zeroed.
        /// This means that the value of `amtDeltas[nextReceivableCycle].thisCycle` is always
        /// relative to 0 or in other words it's an absolute value independent from other cycles.
        mapping(uint32 cycle => AmtDelta) amtDeltas;
    }

    struct AmtDelta {
        /// @notice Amount delta applied on this cycle
        int128 thisCycle;
        /// @notice Amount delta applied on the next cycle
        int128 nextCycle;
    }

    /// @param cycleSecs The length of cycleSecs to be used in the contract instance.
    /// Low value makes funds more available by shortening the average time
    /// of funds being frozen between being taken from the accounts'
    /// streams balance and being receivable by their receivers.
    /// High value makes receiving cheaper by making it process less cycles for a given time range.
    /// Must be higher than 1.
    /// @param streamsStorageSlot The storage slot to holding a single `StreamsStorage` structure.
    constructor(uint32 cycleSecs, bytes32 streamsStorageSlot) {
        require(cycleSecs > 1, "Cycle length too low");
        _cycleSecs = cycleSecs;
        _minAmtPerSec = (_AMT_PER_SEC_MULTIPLIER + cycleSecs - 1) / cycleSecs;
        _streamsStorageSlot = streamsStorageSlot;
    }

    /// @notice Receive streams from unreceived cycles of the account.
    /// Received streams cycles won't need to be analyzed ever again.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// @param maxCycles The maximum number of received streams cycles.
    /// If too low, receiving will be cheap, but may not cover many cycles.
    /// If too high, receiving may become too expensive to fit in a single transaction.
    /// @return receivedAmt The received amount
    function _receiveStreams(uint256 accountId, IERC20 erc20, uint32 maxCycles)
        internal
        returns (uint128 receivedAmt)
    {
        uint32 receivableCycles;
        uint32 fromCycle;
        uint32 toCycle;
        int128 finalAmtPerCycle;
        (receivedAmt, receivableCycles, fromCycle, toCycle, finalAmtPerCycle) =
            _receiveStreamsResult(accountId, erc20, maxCycles);
        if (fromCycle != toCycle) {
            StreamsState storage state = _streamsStorage().states[erc20][accountId];
            state.nextReceivableCycle = toCycle;
            mapping(uint32 cycle => AmtDelta) storage amtDeltas = state.amtDeltas;
            unchecked {
                for (uint32 cycle = fromCycle; cycle < toCycle; cycle++) {
                    delete amtDeltas[cycle];
                }
                // The next cycle delta must be relative to the last received cycle, which deltas
                // got zeroed. In other words the next cycle delta must be an absolute value.
                if (finalAmtPerCycle != 0) {
                    amtDeltas[toCycle].thisCycle += finalAmtPerCycle;
                }
            }
        }
        emit ReceivedStreams(accountId, erc20, receivedAmt, receivableCycles);
    }

    /// @notice Calculate effects of calling `_receiveStreams` with the given parameters.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// @param maxCycles The maximum number of received streams cycles.
    /// If too low, receiving will be cheap, but may not cover many cycles.
    /// If too high, receiving may become too expensive to fit in a single transaction.
    /// @return receivedAmt The amount which would be received
    /// @return receivableCycles The number of cycles which would still be receivable after the call
    /// @return fromCycle The cycle from which funds would be received
    /// @return toCycle The cycle to which funds would be received
    /// @return amtPerCycle The amount per cycle when `toCycle` starts.
    function _receiveStreamsResult(uint256 accountId, IERC20 erc20, uint32 maxCycles)
        internal
        view
        returns (
            uint128 receivedAmt,
            uint32 receivableCycles,
            uint32 fromCycle,
            uint32 toCycle,
            int128 amtPerCycle
        )
    {
        unchecked {
            (fromCycle, toCycle) = _receivableStreamsCyclesRange(accountId, erc20);
            if (toCycle - fromCycle > maxCycles) {
                receivableCycles = toCycle - fromCycle - maxCycles;
                toCycle -= receivableCycles;
            }
            mapping(uint32 cycle => AmtDelta) storage amtDeltas =
                _streamsStorage().states[erc20][accountId].amtDeltas;
            for (uint32 cycle = fromCycle; cycle < toCycle; cycle++) {
                AmtDelta memory amtDelta = amtDeltas[cycle];
                amtPerCycle += amtDelta.thisCycle;
                receivedAmt += uint128(amtPerCycle);
                amtPerCycle += amtDelta.nextCycle;
            }
        }
    }

    /// @notice Counts cycles from which streams can be received.
    /// This function can be used to detect that there are
    /// too many cycles to analyze in a single transaction.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// @return cycles The number of cycles which can be flushed
    function _receivableStreamsCycles(uint256 accountId, IERC20 erc20)
        internal
        view
        returns (uint32 cycles)
    {
        unchecked {
            (uint32 fromCycle, uint32 toCycle) = _receivableStreamsCyclesRange(accountId, erc20);
            return toCycle - fromCycle;
        }
    }

    /// @notice Calculates the cycles range from which streams can be received.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// @return fromCycle The cycle from which funds can be received
    /// @return toCycle The cycle to which funds can be received
    function _receivableStreamsCyclesRange(uint256 accountId, IERC20 erc20)
        private
        view
        returns (uint32 fromCycle, uint32 toCycle)
    {
        fromCycle = _streamsStorage().states[erc20][accountId].nextReceivableCycle;
        toCycle = _cycleOf(_currTimestamp());
        // slither-disable-next-line timestamp
        if (fromCycle == 0 || toCycle < fromCycle) {
            toCycle = fromCycle;
        }
    }

    /// @notice Receive streams from the currently running cycle from a single sender.
    /// It doesn't receive streams from the finished cycles, to do that use `_receiveStreams`.
    /// Squeezed funds won't be received in the next calls
    /// to `_squeezeStreams` or `_receiveStreams`.
    /// Only funds streamed before `block.timestamp` can be squeezed.
    /// @param accountId The ID of the account receiving streams to squeeze funds for.
    /// @param erc20 The used ERC-20 token.
    /// @param senderId The ID of the streaming account to squeeze funds from.
    /// @param historyHash The sender's history hash that was valid right before
    /// they set up the sequence of configurations described by `streamsHistory`.
    /// @param streamsHistory The sequence of the sender's streams configurations.
    /// It can start at an arbitrary past configuration, but must describe all the configurations
    /// which have been used since then including the current one, in the chronological order.
    /// Only streams described by `streamsHistory` will be squeezed.
    /// If `streamsHistory` entries have no receivers, they won't be squeezed.
    /// @return amt The squeezed amount.
    function _squeezeStreams(
        uint256 accountId,
        IERC20 erc20,
        uint256 senderId,
        bytes32 historyHash,
        StreamsHistory[] memory streamsHistory
    ) internal returns (uint128 amt) {
        unchecked {
            uint256 squeezedNum;
            uint256[] memory squeezedRevIdxs;
            bytes32[] memory historyHashes;
            uint256 currCycleConfigs;
            (amt, squeezedNum, squeezedRevIdxs, historyHashes, currCycleConfigs) =
                _squeezeStreamsResult(accountId, erc20, senderId, historyHash, streamsHistory);
            bytes32[] memory squeezedHistoryHashes = new bytes32[](squeezedNum);
            StreamsState storage state = _streamsStorage().states[erc20][accountId];
            uint32[2 ** 32] storage nextSqueezed = state.nextSqueezed[senderId];
            for (uint256 i = 0; i < squeezedNum; i++) {
                // `squeezedRevIdxs` are sorted from the newest configuration to the oldest,
                // but we need to consume them from the oldest to the newest.
                uint256 revIdx = squeezedRevIdxs[squeezedNum - i - 1];
                squeezedHistoryHashes[i] = historyHashes[historyHashes.length - revIdx];
                nextSqueezed[currCycleConfigs - revIdx] = _currTimestamp();
            }
            uint32 cycleStart = _currCycleStart();
            _addDeltaRange(
                state, cycleStart, cycleStart + 1, -int160(amt * _AMT_PER_SEC_MULTIPLIER)
            );
            emit SqueezedStreams(accountId, erc20, senderId, amt, squeezedHistoryHashes);
        }
    }

    /// @notice Calculate effects of calling `_squeezeStreams` with the given parameters.
    /// See its documentation for more details.
    /// @param accountId The ID of the account receiving streams to squeeze funds for.
    /// @param erc20 The used ERC-20 token.
    /// @param senderId The ID of the streaming account to squeeze funds from.
    /// @param historyHash The sender's history hash that was valid right before `streamsHistory`.
    /// @param streamsHistory The sequence of the sender's streams configurations.
    /// @return amt The squeezed amount.
    /// @return squeezedNum The number of squeezed history entries.
    /// @return squeezedRevIdxs The indexes of the squeezed history entries.
    /// The indexes are reversed, meaning that to get the actual index in an array,
    /// they must counted from the end of arrays, as in `arrayLength - squeezedRevIdxs[i]`.
    /// These indexes can be safely used to access `streamsHistory`, `historyHashes`
    /// and `nextSqueezed` regardless of their lengths.
    /// `squeezeRevIdxs` is sorted ascending, from pointing at the most recent entry to the oldest.
    /// @return historyHashes The history hashes valid
    /// for squeezing each of `streamsHistory` entries.
    /// In other words history hashes which had been valid right before each streams
    /// configuration was set, matching `streamsHistoryHash` emitted in its `StreamsSet`.
    /// The first item is always equal to `historyHash`.
    /// @return currCycleConfigs The number of the sender's
    /// streams configurations which have been seen in the current cycle.
    /// This is also the number of used entries in each of the sender's `nextSqueezed` arrays.
    function _squeezeStreamsResult(
        uint256 accountId,
        IERC20 erc20,
        uint256 senderId,
        bytes32 historyHash,
        StreamsHistory[] memory streamsHistory
    )
        internal
        view
        returns (
            uint128 amt,
            uint256 squeezedNum,
            uint256[] memory squeezedRevIdxs,
            bytes32[] memory historyHashes,
            uint256 currCycleConfigs
        )
    {
        {
            StreamsState storage sender = _streamsStorage().states[erc20][senderId];
            historyHashes =
                _verifyStreamsHistory(historyHash, streamsHistory, sender.streamsHistoryHash);
            // If the last update was not in the current cycle,
            // there's only the single latest history entry to squeeze in the current cycle.
            currCycleConfigs = 1;
            // slither-disable-next-line timestamp
            if (sender.updateTime >= _currCycleStart()) currCycleConfigs = sender.currCycleConfigs;
        }
        squeezedRevIdxs = new uint256[](streamsHistory.length);
        uint32[2 ** 32] storage nextSqueezed =
            _streamsStorage().states[erc20][accountId].nextSqueezed[senderId];
        uint32 squeezeEndCap = _currTimestamp();
        unchecked {
            for (uint256 i = 1; i <= streamsHistory.length && i <= currCycleConfigs; i++) {
                StreamsHistory memory historyEntry = streamsHistory[streamsHistory.length - i];
                if (historyEntry.receivers.length != 0) {
                    uint32 squeezeStartCap = nextSqueezed[currCycleConfigs - i];
                    if (squeezeStartCap < _currCycleStart()) squeezeStartCap = _currCycleStart();
                    if (squeezeStartCap < historyEntry.updateTime) {
                        squeezeStartCap = historyEntry.updateTime;
                    }
                    if (squeezeStartCap < squeezeEndCap) {
                        squeezedRevIdxs[squeezedNum++] = i;
                        amt += _squeezedAmt(accountId, historyEntry, squeezeStartCap, squeezeEndCap);
                    }
                }
                squeezeEndCap = historyEntry.updateTime;
            }
        }
    }

    /// @notice Verify a streams history and revert if it's invalid.
    /// @param historyHash The account's history hash that was valid right before `streamsHistory`.
    /// @param streamsHistory The sequence of the account's streams configurations.
    /// @param finalHistoryHash The history hash at the end of `streamsHistory`.
    /// @return historyHashes The history hashes valid
    /// for squeezing each of `streamsHistory` entries.
    /// In other words history hashes which had been valid right before each streams
    /// configuration was set, matching `streamsHistoryHash`es emitted in `StreamsSet`.
    /// The first item is always equal to `historyHash` and `finalHistoryHash` is never included.
    function _verifyStreamsHistory(
        bytes32 historyHash,
        StreamsHistory[] memory streamsHistory,
        bytes32 finalHistoryHash
    ) private pure returns (bytes32[] memory historyHashes) {
        historyHashes = new bytes32[](streamsHistory.length);
        for (uint256 i = 0; i < streamsHistory.length; i++) {
            StreamsHistory memory historyEntry = streamsHistory[i];
            bytes32 streamsHash = historyEntry.streamsHash;
            if (historyEntry.receivers.length != 0) {
                require(streamsHash == 0, "Entry with hash and receivers");
                streamsHash = _hashStreams(historyEntry.receivers);
            }
            historyHashes[i] = historyHash;
            historyHash = _hashStreamsHistory(
                historyHash, streamsHash, historyEntry.updateTime, historyEntry.maxEnd
            );
        }
        // slither-disable-next-line incorrect-equality,timestamp
        require(historyHash == finalHistoryHash, "Invalid streams history");
    }

    /// @notice Calculate the amount squeezable by an account from a single streams history entry.
    /// @param accountId The ID of the account to squeeze streams for.
    /// @param historyEntry The squeezed history entry.
    /// @param squeezeStartCap The squeezed time range start.
    /// @param squeezeEndCap The squeezed time range end.
    /// @return squeezedAmt The squeezed amount.
    function _squeezedAmt(
        uint256 accountId,
        StreamsHistory memory historyEntry,
        uint32 squeezeStartCap,
        uint32 squeezeEndCap
    ) private view returns (uint128 squeezedAmt) {
        unchecked {
            StreamReceiver[] memory receivers = historyEntry.receivers;
            // Binary search for the `idx` of the first occurrence of `accountId`
            uint256 idx = 0;
            for (uint256 idxCap = receivers.length; idx < idxCap;) {
                uint256 idxMid = (idx + idxCap) / 2;
                if (receivers[idxMid].accountId < accountId) {
                    idx = idxMid + 1;
                } else {
                    idxCap = idxMid;
                }
            }
            uint32 updateTime = historyEntry.updateTime;
            uint32 maxEnd = historyEntry.maxEnd;
            uint256 amt = 0;
            for (; idx < receivers.length; idx++) {
                StreamReceiver memory receiver = receivers[idx];
                if (receiver.accountId != accountId) break;
                (uint32 start, uint32 end) =
                    _streamRange(receiver, updateTime, maxEnd, squeezeStartCap, squeezeEndCap);
                amt += _streamedAmt(receiver.config.amtPerSec(), start, end);
            }
            return uint128(amt);
        }
    }

    /// @notice Current account streams state.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// @return streamsHash The current streams receivers list hash, see `_hashStreams`
    /// @return streamsHistoryHash The current streams history hash, see `_hashStreamsHistory`.
    /// @return updateTime The time when streams have been configured for the last time.
    /// @return balance The balance when streams have been configured for the last time.
    /// @return maxEnd The current maximum end time of streaming.
    function _streamsState(uint256 accountId, IERC20 erc20)
        internal
        view
        returns (
            bytes32 streamsHash,
            bytes32 streamsHistoryHash,
            uint32 updateTime,
            uint128 balance,
            uint32 maxEnd
        )
    {
        StreamsState storage state = _streamsStorage().states[erc20][accountId];
        return (
            state.streamsHash,
            state.streamsHistoryHash,
            state.updateTime,
            state.balance,
            state.maxEnd
        );
    }

    /// @notice The account's streams balance at the given timestamp.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// @param currReceivers The current streams receivers list.
    /// It must be exactly the same as the last list set for the account with `_setStreams`.
    /// @param timestamp The timestamps for which balance should be calculated.
    /// It can't be lower than the timestamp of the last call to `_setStreams`.
    /// If it's bigger than `block.timestamp`, then it's a prediction assuming
    /// that `_setStreams` won't be called before `timestamp`.
    /// @return balance The account balance on `timestamp`
    function _balanceAt(
        uint256 accountId,
        IERC20 erc20,
        StreamReceiver[] memory currReceivers,
        uint32 timestamp
    ) internal view returns (uint128 balance) {
        StreamsState storage state = _streamsStorage().states[erc20][accountId];
        require(timestamp >= state.updateTime, "Timestamp before the last update");
        _verifyStreamsReceivers(currReceivers, state);
        return _calcBalance(state.balance, state.updateTime, state.maxEnd, currReceivers, timestamp);
    }

    /// @notice Calculates the streams balance at a given timestamp.
    /// @param lastBalance The balance when streaming started.
    /// @param lastUpdate The timestamp when streaming started.
    /// @param maxEnd The maximum end time of streaming.
    /// @param receivers The list of streams receivers.
    /// @param timestamp The timestamps for which balance should be calculated.
    /// It can't be lower than `lastUpdate`.
    /// If it's bigger than `block.timestamp`, then it's a prediction assuming
    /// that `_setStreams` won't be called before `timestamp`.
    /// @return balance The account balance on `timestamp`
    function _calcBalance(
        uint128 lastBalance,
        uint32 lastUpdate,
        uint32 maxEnd,
        StreamReceiver[] memory receivers,
        uint32 timestamp
    ) private view returns (uint128 balance) {
        unchecked {
            balance = lastBalance;
            for (uint256 i = 0; i < receivers.length; i++) {
                StreamReceiver memory receiver = receivers[i];
                (uint32 start, uint32 end) = _streamRange({
                    receiver: receiver,
                    updateTime: lastUpdate,
                    maxEnd: maxEnd,
                    startCap: lastUpdate,
                    endCap: timestamp
                });
                balance -= uint128(_streamedAmt(receiver.config.amtPerSec(), start, end));
            }
        }
    }

    /// @notice Sets the account's streams configuration.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// @param currReceivers The current streams receivers list.
    /// It must be exactly the same as the last list set for the account with `_setStreams`.
    /// If this is the first update, pass an empty array.
    /// @param balanceDelta The streams balance change being applied.
    /// Positive when adding funds to the streams balance, negative to removing them.
    /// @param newReceivers The list of the streams receivers of the account to be set.
    /// Must be sorted, deduplicated and without 0 amtPerSecs.
    /// @param maxEndHint1 An optional parameter allowing gas optimization, pass `0` to ignore it.
    /// The first hint for finding the maximum end time when all streams stop due to funds
    /// running out after the balance is updated and the new receivers list is applied.
    /// Hints have no effect on the results of calling this function, except potentially saving gas.
    /// Hints are Unix timestamps used as the starting points for binary search for the time
    /// when funds run out in the range of timestamps from the current block's to `2^32`.
    /// Hints lower than the current timestamp are ignored.
    /// You can provide zero, one or two hints. The order of hints doesn't matter.
    /// Hints are the most effective when one of them is lower than or equal to
    /// the last timestamp when funds are still streamed, and the other one is strictly larger
    /// than that timestamp,the smaller the difference between such hints, the higher gas savings.
    /// The savings are the highest possible when one of the hints is equal to
    /// the last timestamp when funds are still streamed, and the other one is larger by 1.
    /// It's worth noting that the exact timestamp of the block in which this function is executed
    /// may affect correctness of the hints, especially if they're precise.
    /// Hints don't provide any benefits when balance is not enough to cover
    /// a single second of streaming or is enough to cover all streams until timestamp `2^32`.
    /// Even inaccurate hints can be useful, and providing a single hint
    /// or two hints that don't enclose the time when funds run out can still save some gas.
    /// Providing poor hints that don't reduce the number of binary search steps
    /// may cause slightly higher gas usage than not providing any hints.
    /// @param maxEndHint2 An optional parameter allowing gas optimization, pass `0` to ignore it.
    /// The second hint for finding the maximum end time, see `maxEndHint1` docs for more details.
    /// @return realBalanceDelta The actually applied streams balance change.
    function _setStreams(
        uint256 accountId,
        IERC20 erc20,
        StreamReceiver[] memory currReceivers,
        int128 balanceDelta,
        StreamReceiver[] memory newReceivers,
        // slither-disable-next-line similar-names
        uint32 maxEndHint1,
        uint32 maxEndHint2
    ) internal returns (int128 realBalanceDelta) {
        unchecked {
            StreamsState storage state = _streamsStorage().states[erc20][accountId];
            _verifyStreamsReceivers(currReceivers, state);
            uint32 lastUpdate = state.updateTime;
            uint128 newBalance;
            uint32 newMaxEnd;
            {
                uint32 currMaxEnd = state.maxEnd;
                int128 currBalance = int128(
                    _calcBalance(
                        state.balance, lastUpdate, currMaxEnd, currReceivers, _currTimestamp()
                    )
                );
                realBalanceDelta = balanceDelta;
                // Cap `realBalanceDelta` at withdrawal of the entire `currBalance`
                if (realBalanceDelta < -currBalance) {
                    realBalanceDelta = -currBalance;
                }
                newBalance = uint128(currBalance + realBalanceDelta);
                newMaxEnd = _calcMaxEnd(newBalance, newReceivers, maxEndHint1, maxEndHint2);
                _updateReceiverStates(
                    _streamsStorage().states[erc20],
                    currReceivers,
                    lastUpdate,
                    currMaxEnd,
                    newReceivers,
                    newMaxEnd
                );
            }
            state.updateTime = _currTimestamp();
            state.maxEnd = newMaxEnd;
            state.balance = newBalance;
            bytes32 streamsHistory = state.streamsHistoryHash;
            // slither-disable-next-line timestamp
            if (streamsHistory != 0 && _cycleOf(lastUpdate) != _cycleOf(_currTimestamp())) {
                state.currCycleConfigs = 2;
            } else {
                state.currCycleConfigs++;
            }
            bytes32 newStreamsHash = _hashStreams(newReceivers);
            state.streamsHistoryHash =
                _hashStreamsHistory(streamsHistory, newStreamsHash, _currTimestamp(), newMaxEnd);
            emit StreamsSet(accountId, erc20, newStreamsHash, streamsHistory, newBalance, newMaxEnd);
            // slither-disable-next-line timestamp
            if (newStreamsHash != state.streamsHash) {
                state.streamsHash = newStreamsHash;
                for (uint256 i = 0; i < newReceivers.length; i++) {
                    StreamReceiver memory receiver = newReceivers[i];
                    emit StreamReceiverSeen(newStreamsHash, receiver.accountId, receiver.config);
                }
            }
        }
    }

    /// @notice Verifies that the provided list of receivers is currently active for the account.
    /// @param currReceivers The verified list of receivers.
    /// @param state The account's state.
    function _verifyStreamsReceivers(
        StreamReceiver[] memory currReceivers,
        StreamsState storage state
    ) private view {
        require(_hashStreams(currReceivers) == state.streamsHash, "Invalid streams receivers list");
    }

    /// @notice Calculates the maximum end time of all streams.
    /// @param balance The balance when streaming starts.
    /// @param receivers The list of streams receivers.
    /// Must be sorted, deduplicated and without 0 amtPerSecs.
    /// @param hint1 The first hint for finding the maximum end time.
    /// See `_setStreams` docs for `maxEndHint1` for more details.
    /// @param hint2 The second hint for finding the maximum end time.
    /// See `_setStreams` docs for `maxEndHint2` for more details.
    /// @return maxEnd The maximum end time of streaming.
    function _calcMaxEnd(
        uint128 balance,
        StreamReceiver[] memory receivers,
        uint32 hint1,
        uint32 hint2
    ) private view returns (uint32 maxEnd) {
        (uint256[] memory configs, uint256 configsLen) = _buildConfigs(receivers);

        uint256 enoughEnd = _currTimestamp();
        // slither-disable-start incorrect-equality,timestamp
        if (configsLen == 0 || balance == 0) {
            return uint32(enoughEnd);
        }

        uint256 notEnoughEnd = type(uint32).max;
        if (_isBalanceEnough(balance, configs, configsLen, notEnoughEnd)) {
            return uint32(notEnoughEnd);
        }

        if (hint1 > enoughEnd && hint1 < notEnoughEnd) {
            if (_isBalanceEnough(balance, configs, configsLen, hint1)) {
                enoughEnd = hint1;
            } else {
                notEnoughEnd = hint1;
            }
        }

        if (hint2 > enoughEnd && hint2 < notEnoughEnd) {
            if (_isBalanceEnough(balance, configs, configsLen, hint2)) {
                enoughEnd = hint2;
            } else {
                notEnoughEnd = hint2;
            }
        }

        while (true) {
            uint256 end;
            unchecked {
                end = (enoughEnd + notEnoughEnd) / 2;
            }
            if (end == enoughEnd) {
                return uint32(end);
            }
            if (_isBalanceEnough(balance, configs, configsLen, end)) {
                enoughEnd = end;
            } else {
                notEnoughEnd = end;
            }
        }
        // slither-disable-end incorrect-equality,timestamp
    }

    /// @notice Check if a given balance is enough to cover all streams with the given `maxEnd`.
    /// @param balance The balance when streaming starts.
    /// @param configs The list of streams configurations.
    /// @param configsLen The length of `configs`.
    /// @param maxEnd The maximum end time of streaming.
    /// @return isEnough `true` if the balance is enough, `false` otherwise.
    function _isBalanceEnough(
        uint256 balance,
        uint256[] memory configs,
        uint256 configsLen,
        uint256 maxEnd
    ) private view returns (bool isEnough) {
        unchecked {
            uint256 spent = 0;
            for (uint256 i = 0; i < configsLen; i++) {
                (uint256 amtPerSec, uint256 start, uint256 end) = _getConfig(configs, i);
                // slither-disable-next-line timestamp
                if (maxEnd <= start) {
                    continue;
                }
                // slither-disable-next-line timestamp
                if (end > maxEnd) {
                    end = maxEnd;
                }
                spent += _streamedAmt(amtPerSec, start, end);
                if (spent > balance) {
                    return false;
                }
            }
            return true;
        }
    }

    /// @notice Build a preprocessed list of streams configurations from receivers.
    /// @param receivers The list of streams receivers.
    /// Must be sorted, deduplicated and without 0 amtPerSecs.
    /// @return configs The list of streams configurations
    /// @return configsLen The length of `configs`
    function _buildConfigs(StreamReceiver[] memory receivers)
        private
        view
        returns (uint256[] memory configs, uint256 configsLen)
    {
        unchecked {
            require(receivers.length <= _MAX_STREAMS_RECEIVERS, "Too many streams receivers");
            configs = new uint256[](receivers.length);
            for (uint256 i = 0; i < receivers.length; i++) {
                StreamReceiver memory receiver = receivers[i];
                if (i > 0) {
                    require(_isOrdered(receivers[i - 1], receiver), "Streams receivers not sorted");
                }
                configsLen = _addConfig(configs, configsLen, receiver);
            }
        }
    }

    /// @notice Preprocess and add a stream receiver to the list of configurations.
    /// @param configs The list of streams configurations
    /// @param configsLen The length of `configs`
    /// @param receiver The added stream receiver.
    /// @return newConfigsLen The new length of `configs`
    function _addConfig(
        uint256[] memory configs,
        uint256 configsLen,
        StreamReceiver memory receiver
    ) private view returns (uint256 newConfigsLen) {
        uint160 amtPerSec = receiver.config.amtPerSec();
        require(amtPerSec >= _minAmtPerSec, "Stream receiver amtPerSec too low");
        (uint32 start, uint32 end) =
            _streamRangeInFuture(receiver, _currTimestamp(), type(uint32).max);
        // slither-disable-next-line incorrect-equality,timestamp
        if (start == end) {
            return configsLen;
        }
        // By assignment we get `config` value:
        // `zeros (96 bits) | amtPerSec (160 bits)`
        uint256 config = amtPerSec;
        // By bit shifting we get `config` value:
        // `zeros (64 bits) | amtPerSec (160 bits) | zeros (32 bits)`
        // By bit masking we get `config` value:
        // `zeros (64 bits) | amtPerSec (160 bits) | start (32 bits)`
        config = (config << 32) | start;
        // By bit shifting we get `config` value:
        // `zeros (32 bits) | amtPerSec (160 bits) | start (32 bits) | zeros (32 bits)`
        // By bit masking we get `config` value:
        // `zeros (32 bits) | amtPerSec (160 bits) | start (32 bits) | end (32 bits)`
        config = (config << 32) | end;
        configs[configsLen] = config;
        unchecked {
            return configsLen + 1;
        }
    }

    /// @notice Load a streams configuration from the list.
    /// @param configs The list of streams configurations
    /// @param idx The loaded configuration index. It must be smaller than the `configs` length.
    /// @return amtPerSec The amount per second being streamed.
    /// @return start The timestamp when streaming starts.
    /// @return end The maximum timestamp when streaming ends.
    function _getConfig(uint256[] memory configs, uint256 idx)
        private
        pure
        returns (uint256 amtPerSec, uint256 start, uint256 end)
    {
        uint256 config;
        // `config` has value:
        // `zeros (32 bits) | amtPerSec (160 bits) | start (32 bits) | end (32 bits)`
        // slither-disable-next-line assembly
        assembly ("memory-safe") {
            config := mload(add(32, add(configs, shl(5, idx))))
        }
        // By bit shifting we get value:
        // `zeros (96 bits) | amtPerSec (160 bits)`
        amtPerSec = config >> 64;
        // By bit shifting we get value:
        // `zeros (64 bits) | amtPerSec (160 bits) | start (32 bits)`
        // By casting down we get value:
        // `start (32 bits)`
        start = uint32(config >> 32);
        // By casting down we get value:
        // `end (32 bits)`
        end = uint32(config);
    }

    /// @notice Calculates the hash of the streams configuration.
    /// It's used to verify if streams configuration is the previously set one.
    /// @param receivers The list of the streams receivers.
    /// Must be sorted, deduplicated and without 0 amtPerSecs.
    /// If the streams have never been updated, pass an empty array.
    /// @return streamsHash The hash of the streams configuration
    function _hashStreams(StreamReceiver[] memory receivers)
        internal
        pure
        returns (bytes32 streamsHash)
    {
        if (receivers.length == 0) {
            return bytes32(0);
        }
        return keccak256(abi.encode(receivers));
    }

    /// @notice Calculates the hash of the streams history
    /// after the streams configuration is updated.
    /// @param oldStreamsHistoryHash The history hash
    /// that was valid before the streams were updated.
    /// The `streamsHistoryHash` of an account before they set streams for the first time is `0`.
    /// @param streamsHash The hash of the streams receivers being set.
    /// @param updateTime The timestamp when the streams were updated.
    /// @param maxEnd The maximum end of the streams being set.
    /// @return streamsHistoryHash The hash of the updated streams history.
    function _hashStreamsHistory(
        bytes32 oldStreamsHistoryHash,
        bytes32 streamsHash,
        uint32 updateTime,
        uint32 maxEnd
    ) internal pure returns (bytes32 streamsHistoryHash) {
        return keccak256(abi.encode(oldStreamsHistoryHash, streamsHash, updateTime, maxEnd));
    }

    /// @notice Applies the effects of the change of the streams on the receivers' streams state.
    /// @param states The streams states for the used ERC-20 token.
    /// @param currReceivers The list of the streams receivers
    /// set in the last streams update of the account.
    /// If this is the first update, pass an empty array.
    /// @param lastUpdate the last time the sender updated the streams.
    /// If this is the first update, pass zero.
    /// @param currMaxEnd The maximum end time of streaming according to the last streams update.
    /// @param newReceivers  The list of the streams receivers of the account to be set.
    /// Must be sorted, deduplicated and without 0 amtPerSecs.
    /// @param newMaxEnd The maximum end time of streaming according to the new configuration.
    // slither-disable-next-line cyclomatic-complexity
    function _updateReceiverStates(
        mapping(uint256 accountId => StreamsState) storage states,
        StreamReceiver[] memory currReceivers,
        uint32 lastUpdate,
        uint32 currMaxEnd,
        StreamReceiver[] memory newReceivers,
        uint32 newMaxEnd
    ) private {
        uint256 currIdx = 0;
        uint256 newIdx = 0;
        while (true) {
            bool pickCurr = currIdx < currReceivers.length;
            // slither-disable-next-line uninitialized-local
            StreamReceiver memory currRecv;
            if (pickCurr) {
                currRecv = currReceivers[currIdx];
            }

            bool pickNew = newIdx < newReceivers.length;
            // slither-disable-next-line uninitialized-local
            StreamReceiver memory newRecv;
            if (pickNew) {
                newRecv = newReceivers[newIdx];
            }

            // Limit picking both curr and new to situations when they differ only by time
            if (pickCurr && pickNew) {
                if (
                    currRecv.accountId != newRecv.accountId
                        || currRecv.config.amtPerSec() != newRecv.config.amtPerSec()
                ) {
                    pickCurr = _isOrdered(currRecv, newRecv);
                    pickNew = !pickCurr;
                }
            }

            if (pickCurr && pickNew) {
                // Shift the existing stream to fulfil the new configuration
                StreamsState storage state = states[currRecv.accountId];
                (uint32 currStart, uint32 currEnd) =
                    _streamRangeInFuture(currRecv, lastUpdate, currMaxEnd);
                (uint32 newStart, uint32 newEnd) =
                    _streamRangeInFuture(newRecv, _currTimestamp(), newMaxEnd);
                int256 amtPerSec = int256(uint256(currRecv.config.amtPerSec()));
                // Move the start and end times if updated. This has the same effects as calling
                // _addDeltaRange(state, currStart, currEnd, -amtPerSec);
                // _addDeltaRange(state, newStart, newEnd, amtPerSec);
                // but it allows skipping storage access if there's no change to the starts or ends.
                _addDeltaRange(state, currStart, newStart, -amtPerSec);
                _addDeltaRange(state, currEnd, newEnd, amtPerSec);
                // Ensure that the account receives the updated cycles
                uint32 currStartCycle = _cycleOf(currStart);
                uint32 newStartCycle = _cycleOf(newStart);
                // The `currStartCycle > newStartCycle` check is just an optimization.
                // If it's false, then `state.nextReceivableCycle > newStartCycle` must be
                // false too, there's no need to pay for the storage access to check it.
                // slither-disable-next-line timestamp
                if (currStartCycle > newStartCycle && state.nextReceivableCycle > newStartCycle) {
                    state.nextReceivableCycle = newStartCycle;
                }
            } else if (pickCurr) {
                // Remove an existing stream
                // slither-disable-next-line similar-names
                StreamsState storage state = states[currRecv.accountId];
                (uint32 start, uint32 end) = _streamRangeInFuture(currRecv, lastUpdate, currMaxEnd);
                // slither-disable-next-line similar-names
                int256 amtPerSec = int256(uint256(currRecv.config.amtPerSec()));
                _addDeltaRange(state, start, end, -amtPerSec);
            } else if (pickNew) {
                // Create a new stream
                StreamsState storage state = states[newRecv.accountId];
                // slither-disable-next-line uninitialized-local
                (uint32 start, uint32 end) =
                    _streamRangeInFuture(newRecv, _currTimestamp(), newMaxEnd);
                int256 amtPerSec = int256(uint256(newRecv.config.amtPerSec()));
                _addDeltaRange(state, start, end, amtPerSec);
                // Ensure that the account receives the updated cycles
                uint32 startCycle = _cycleOf(start);
                // slither-disable-next-line timestamp
                uint32 nextReceivableCycle = state.nextReceivableCycle;
                if (nextReceivableCycle == 0 || nextReceivableCycle > startCycle) {
                    state.nextReceivableCycle = startCycle;
                }
            } else {
                break;
            }

            unchecked {
                if (pickCurr) {
                    currIdx++;
                }
                if (pickNew) {
                    newIdx++;
                }
            }
        }
    }

    /// @notice Calculates the time range in the future in which a receiver will be streamed to.
    /// @param receiver The stream receiver.
    /// @param maxEnd The maximum end time of streaming.
    function _streamRangeInFuture(StreamReceiver memory receiver, uint32 updateTime, uint32 maxEnd)
        private
        view
        returns (uint32 start, uint32 end)
    {
        return _streamRange(receiver, updateTime, maxEnd, _currTimestamp(), type(uint32).max);
    }

    /// @notice Calculates the time range in which a receiver is to be streamed to.
    /// This range is capped to provide a view on the stream through a specific time window.
    /// @param receiver The stream receiver.
    /// @param updateTime The time when the stream is configured.
    /// @param maxEnd The maximum end time of streaming.
    /// @param startCap The timestamp the streaming range start should be capped to.
    /// @param endCap The timestamp the streaming range end should be capped to.
    function _streamRange(
        StreamReceiver memory receiver,
        uint32 updateTime,
        uint32 maxEnd,
        uint32 startCap,
        uint32 endCap
    ) private pure returns (uint32 start, uint32 end_) {
        start = receiver.config.start();
        // slither-disable-start timestamp
        if (start == 0) {
            start = updateTime;
        }
        uint40 end;
        unchecked {
            end = uint40(start) + receiver.config.duration();
        }
        // slither-disable-next-line incorrect-equality
        if (end == start || end > maxEnd) {
            end = maxEnd;
        }
        if (start < startCap) {
            start = startCap;
        }
        if (end > endCap) {
            end = endCap;
        }
        if (end < start) {
            end = start;
        }
        // slither-disable-end timestamp
        return (start, uint32(end));
    }

    /// @notice Adds funds received by an account in a given time range
    /// @param state The account state
    /// @param start The timestamp from which the delta takes effect
    /// @param end The timestamp until which the delta takes effect
    /// @param amtPerSec The streaming rate
    function _addDeltaRange(StreamsState storage state, uint32 start, uint32 end, int256 amtPerSec)
        private
    {
        // slither-disable-next-line incorrect-equality,timestamp
        if (start == end) {
            return;
        }
        mapping(uint32 cycle => AmtDelta) storage amtDeltas = state.amtDeltas;
        _addDelta(amtDeltas, start, amtPerSec);
        _addDelta(amtDeltas, end, -amtPerSec);
    }

    /// @notice Adds delta of funds received by an account at a given time
    /// @param amtDeltas The account amount deltas
    /// @param timestamp The timestamp when the deltas need to be added
    /// @param amtPerSec The streaming rate
    function _addDelta(
        mapping(uint32 cycle => AmtDelta) storage amtDeltas,
        uint256 timestamp,
        int256 amtPerSec
    ) private {
        unchecked {
            // In order to set a delta on a specific timestamp it must be introduced in two cycles.
            // These formulas follow the logic from `_streamedAmt`, see it for more details.
            int256 amtPerSecMultiplier = int160(_AMT_PER_SEC_MULTIPLIER);
            int256 fullCycle = (int256(uint256(_cycleSecs)) * amtPerSec) / amtPerSecMultiplier;
            // slither-disable-next-line weak-prng
            int256 nextCycle = (int256(timestamp % _cycleSecs) * amtPerSec) / amtPerSecMultiplier;
            AmtDelta storage amtDelta = amtDeltas[_cycleOf(uint32(timestamp))];
            // Any over- or under-flows are fine, they're guaranteed to be fixed by a matching
            // under- or over-flow from the other call to `_addDelta` made by `_addDeltaRange`.
            // This is because the total balance of `Streams` can never exceed `type(int128).max`,
            // so in the end no amtDelta can have delta higher than `type(int128).max`.
            amtDelta.thisCycle += int128(fullCycle - nextCycle);
            amtDelta.nextCycle += int128(nextCycle);
        }
    }

    /// @notice Checks if two receivers fulfil the sortedness requirement of the receivers list.
    /// @param prev The previous receiver
    /// @param next The next receiver
    function _isOrdered(StreamReceiver memory prev, StreamReceiver memory next)
        private
        pure
        returns (bool)
    {
        if (prev.accountId != next.accountId) {
            return prev.accountId < next.accountId;
        }
        return prev.config.lt(next.config);
    }

    /// @notice Calculates the amount streamed over a time range.
    /// The amount streamed in the `N`th second of each cycle is:
    /// `(N + 1) * amtPerSec / AMT_PER_SEC_MULTIPLIER - N * amtPerSec / AMT_PER_SEC_MULTIPLIER`.
    /// For a range of `N`s from `0` to `M` the sum of the streamed amounts is calculated as:
    /// `M * amtPerSec / AMT_PER_SEC_MULTIPLIER` assuming that `M <= cycleSecs`.
    /// For an arbitrary time range across multiple cycles the amount
    /// is calculated as the sum of the amount streamed in the start cycle,
    /// each of the full cycles in between and the end cycle.
    /// This algorithm has the following properties:
    /// - During every second full units are streamed, there are no partially streamed units.
    /// - Unstreamed fractions are streamed when they add up into full units.
    /// - Unstreamed fractions don't add up across cycle end boundaries.
    /// - Some seconds stream more units and some less.
    /// - Every `N`th second of each cycle streams the same amount.
    /// - Every full cycle streams the same amount.
    /// - The amount streamed in a given second is independent from the streaming start and end.
    /// - Streaming over time ranges `A:B` and then `B:C` is equivalent to streaming over `A:C`.
    /// - Different streams existing in the system don't interfere with each other.
    /// @param amtPerSec The streaming rate
    /// @param start The streaming start time
    /// @param end The streaming end time
    /// @return amt The streamed amount
    function _streamedAmt(uint256 amtPerSec, uint256 start, uint256 end)
        private
        view
        returns (uint256 amt)
    {
        // This function is written in Yul because it can be called thousands of times
        // per transaction and it needs to be optimized as much as possible.
        // As of Solidity 0.8.13, rewriting it in unchecked Solidity triples its gas cost.
        uint256 cycleSecs = _cycleSecs;
        // slither-disable-next-line assembly
        assembly {
            let endedCycles := sub(div(end, cycleSecs), div(start, cycleSecs))
            // slither-disable-next-line divide-before-multiply
            let amtPerCycle := div(mul(cycleSecs, amtPerSec), _AMT_PER_SEC_MULTIPLIER)
            amt := mul(endedCycles, amtPerCycle)
            // slither-disable-next-line weak-prng
            let amtEnd := div(mul(mod(end, cycleSecs), amtPerSec), _AMT_PER_SEC_MULTIPLIER)
            amt := add(amt, amtEnd)
            // slither-disable-next-line weak-prng
            let amtStart := div(mul(mod(start, cycleSecs), amtPerSec), _AMT_PER_SEC_MULTIPLIER)
            amt := sub(amt, amtStart)
        }
    }

    /// @notice Calculates the cycle containing the given timestamp.
    /// @param timestamp The timestamp.
    /// @return cycle The cycle containing the timestamp.
    function _cycleOf(uint32 timestamp) private view returns (uint32 cycle) {
        unchecked {
            return timestamp / _cycleSecs + 1;
        }
    }

    /// @notice The current timestamp, casted to the contract's internal representation.
    /// @return timestamp The current timestamp
    function _currTimestamp() private view returns (uint32 timestamp) {
        return uint32(block.timestamp);
    }

    /// @notice The current cycle start timestamp, casted to the contract's internal representation.
    /// @return timestamp The current cycle start timestamp
    function _currCycleStart() private view returns (uint32 timestamp) {
        unchecked {
            uint32 currTimestamp = _currTimestamp();
            // slither-disable-next-line weak-prng
            return currTimestamp - (currTimestamp % _cycleSecs);
        }
    }

    /// @notice Returns the Streams storage.
    /// @return streamsStorage The storage.
    function _streamsStorage() private view returns (StreamsStorage storage streamsStorage) {
        bytes32 slot = _streamsStorageSlot;
        // slither-disable-next-line assembly
        assembly {
            streamsStorage.slot := slot
        }
    }
}