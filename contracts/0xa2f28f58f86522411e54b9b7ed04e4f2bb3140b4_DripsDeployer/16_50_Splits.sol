// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

/// @notice A splits receiver
struct SplitsReceiver {
    /// @notice The account ID.
    uint256 accountId;
    /// @notice The splits weight. Must never be zero.
    /// The account will be getting `weight / _TOTAL_SPLITS_WEIGHT`
    /// share of the funds collected by the splitting account.
    uint32 weight;
}

/// @notice Splits can keep track of at most `type(uint128).max`
/// which is `2 ^ 128 - 1` units of each ERC-20 token.
/// It's up to the caller to guarantee that this limit is never exceeded,
/// failing to do so may result in a total protocol collapse.
abstract contract Splits {
    /// @notice Maximum number of splits receivers of a single account.
    /// Limits the cost of splitting.
    uint256 internal constant _MAX_SPLITS_RECEIVERS = 200;
    /// @notice The total splits weight of an account.
    uint32 internal constant _TOTAL_SPLITS_WEIGHT = 1_000_000;
    /// @notice The amount the contract can keep track of each ERC-20 token.
    // slither-disable-next-line unused-state
    uint128 internal constant _MAX_SPLITS_BALANCE = type(uint128).max;
    /// @notice The storage slot holding a single `SplitsStorage` structure.
    bytes32 private immutable _splitsStorageSlot;

    /// @notice Emitted when an account collects funds
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// @param collected The collected amount
    event Collected(uint256 indexed accountId, IERC20 indexed erc20, uint128 collected);

    /// @notice Emitted when funds are split from an account to a receiver.
    /// This is caused by the account collecting received funds.
    /// @param accountId The account ID.
    /// @param receiver The splits receiver account ID
    /// @param erc20 The used ERC-20 token.
    /// @param amt The amount split to the receiver
    event Split(
        uint256 indexed accountId, uint256 indexed receiver, IERC20 indexed erc20, uint128 amt
    );

    /// @notice Emitted when funds are made collectable after splitting.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// @param amt The amount made collectable for the account
    /// on top of what was collectable before.
    event Collectable(uint256 indexed accountId, IERC20 indexed erc20, uint128 amt);

    /// @notice Emitted when funds are given from the account to the receiver.
    /// @param accountId The account ID.
    /// @param receiver The receiver account ID.
    /// @param erc20 The used ERC-20 token.
    /// @param amt The given amount
    event Given(
        uint256 indexed accountId, uint256 indexed receiver, IERC20 indexed erc20, uint128 amt
    );

    /// @notice Emitted when the account's splits are updated.
    /// @param accountId The account ID.
    /// @param receiversHash The splits receivers list hash
    event SplitsSet(uint256 indexed accountId, bytes32 indexed receiversHash);

    /// @notice Emitted when an account is seen in a splits receivers list.
    /// @param receiversHash The splits receivers list hash
    /// @param accountId The account ID.
    /// @param weight The splits weight. Must never be zero.
    /// The account will be getting `weight / _TOTAL_SPLITS_WEIGHT`
    /// share of the funds collected by the splitting account.
    event SplitsReceiverSeen(
        bytes32 indexed receiversHash, uint256 indexed accountId, uint32 weight
    );

    struct SplitsStorage {
        /// @notice Account splits states.
        mapping(uint256 accountId => SplitsState) splitsStates;
    }

    struct SplitsState {
        /// @notice The account's splits configuration hash, see `hashSplits`.
        bytes32 splitsHash;
        /// @notice The account's splits balances.
        mapping(IERC20 erc20 => SplitsBalance) balances;
    }

    struct SplitsBalance {
        /// @notice The not yet split balance, must be split before collecting by the account.
        uint128 splittable;
        /// @notice The already split balance, ready to be collected by the account.
        uint128 collectable;
    }

    /// @param splitsStorageSlot The storage slot to holding a single `SplitsStorage` structure.
    constructor(bytes32 splitsStorageSlot) {
        _splitsStorageSlot = splitsStorageSlot;
    }

    function _addSplittable(uint256 accountId, IERC20 erc20, uint128 amt) internal {
        _splitsStorage().splitsStates[accountId].balances[erc20].splittable += amt;
    }

    /// @notice Returns account's received but not split yet funds.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// @return amt The amount received but not split yet.
    function _splittable(uint256 accountId, IERC20 erc20) internal view returns (uint128 amt) {
        return _splitsStorage().splitsStates[accountId].balances[erc20].splittable;
    }

    /// @notice Calculate the result of splitting an amount using the current splits configuration.
    /// @param accountId The account ID.
    /// @param currReceivers The list of the account's current splits receivers.
    /// It must be exactly the same as the last list set for the account with `_setSplits`.
    /// @param amount The amount being split.
    /// @return collectableAmt The amount made collectable for the account
    /// on top of what was collectable before.
    /// @return splitAmt The amount split to the account's splits receivers
    function _splitResult(uint256 accountId, SplitsReceiver[] memory currReceivers, uint128 amount)
        internal
        view
        returns (uint128 collectableAmt, uint128 splitAmt)
    {
        _assertCurrSplits(accountId, currReceivers);
        if (amount == 0) {
            return (0, 0);
        }
        unchecked {
            uint160 splitsWeight = 0;
            for (uint256 i = 0; i < currReceivers.length; i++) {
                splitsWeight += currReceivers[i].weight;
            }
            splitAmt = uint128(amount * splitsWeight / _TOTAL_SPLITS_WEIGHT);
            collectableAmt = amount - splitAmt;
        }
    }

    /// @notice Splits the account's splittable funds among receivers.
    /// The entire splittable balance of the given ERC-20 token is split.
    /// All split funds are split using the current splits configuration.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// @param currReceivers The list of the account's current splits receivers.
    /// It must be exactly the same as the last list set for the account with `_setSplits`.
    /// @return collectableAmt The amount made collectable for the account
    /// on top of what was collectable before.
    /// @return splitAmt The amount split to the account's splits receivers
    function _split(uint256 accountId, IERC20 erc20, SplitsReceiver[] memory currReceivers)
        internal
        returns (uint128 collectableAmt, uint128 splitAmt)
    {
        _assertCurrSplits(accountId, currReceivers);
        SplitsBalance storage balance = _splitsStorage().splitsStates[accountId].balances[erc20];

        collectableAmt = balance.splittable;
        if (collectableAmt == 0) {
            return (0, 0);
        }
        balance.splittable = 0;

        unchecked {
            uint160 splitsWeight = 0;
            for (uint256 i = 0; i < currReceivers.length; i++) {
                splitsWeight += currReceivers[i].weight;
                uint128 currSplitAmt =
                    uint128(collectableAmt * splitsWeight / _TOTAL_SPLITS_WEIGHT) - splitAmt;
                splitAmt += currSplitAmt;
                uint256 receiver = currReceivers[i].accountId;
                _addSplittable(receiver, erc20, currSplitAmt);
                emit Split(accountId, receiver, erc20, currSplitAmt);
            }
            collectableAmt -= splitAmt;
            balance.collectable += collectableAmt;
        }
        emit Collectable(accountId, erc20, collectableAmt);
    }

    /// @notice Returns account's received funds already split and ready to be collected.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// @return amt The collectable amount.
    function _collectable(uint256 accountId, IERC20 erc20) internal view returns (uint128 amt) {
        return _splitsStorage().splitsStates[accountId].balances[erc20].collectable;
    }

    /// @notice Collects account's received already split funds.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// @return amt The collected amount
    function _collect(uint256 accountId, IERC20 erc20) internal returns (uint128 amt) {
        SplitsBalance storage balance = _splitsStorage().splitsStates[accountId].balances[erc20];
        amt = balance.collectable;
        balance.collectable = 0;
        emit Collected(accountId, erc20, amt);
    }

    /// @notice Gives funds from the account to the receiver.
    /// The receiver can split and collect them immediately.
    /// @param accountId The account ID.
    /// @param receiver The receiver account ID.
    /// @param erc20 The used ERC-20 token.
    /// @param amt The given amount
    function _give(uint256 accountId, uint256 receiver, IERC20 erc20, uint128 amt) internal {
        _addSplittable(receiver, erc20, amt);
        emit Given(accountId, receiver, erc20, amt);
    }

    /// @notice Sets the account splits configuration.
    /// The configuration is common for all ERC-20 tokens.
    /// Nothing happens to the currently splittable funds, but when they are split
    /// after this function finishes, the new splits configuration will be used.
    /// @param accountId The account ID.
    /// @param receivers The list of the account's splits receivers to be set.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// Each splits receiver will be getting `weight / _TOTAL_SPLITS_WEIGHT`
    /// share of the funds collected by the account.
    /// If the sum of weights of all receivers is less than `_TOTAL_SPLITS_WEIGHT`,
    /// some funds won't be split, but they will be left for the account to collect.
    /// It's valid to include the account's own `accountId` in the list of receivers,
    /// but funds split to themselves return to their splittable balance and are not collectable.
    /// This is usually unwanted, because if splitting is repeated,
    /// funds split to themselves will be again split using the current configuration.
    /// Splitting 100% to self effectively blocks splitting unless the configuration is updated.
    function _setSplits(uint256 accountId, SplitsReceiver[] memory receivers) internal {
        SplitsState storage state = _splitsStorage().splitsStates[accountId];
        bytes32 newSplitsHash = _hashSplits(receivers);
        emit SplitsSet(accountId, newSplitsHash);
        if (newSplitsHash != state.splitsHash) {
            _assertSplitsValid(receivers, newSplitsHash);
            state.splitsHash = newSplitsHash;
        }
    }

    /// @notice Validates a list of splits receivers and emits events for them
    /// @param receivers The list of splits receivers
    /// @param receiversHash The hash of the list of splits receivers.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    function _assertSplitsValid(SplitsReceiver[] memory receivers, bytes32 receiversHash) private {
        unchecked {
            require(receivers.length <= _MAX_SPLITS_RECEIVERS, "Too many splits receivers");
            uint64 totalWeight = 0;
            // slither-disable-next-line uninitialized-local
            uint256 prevAccountId;
            for (uint256 i = 0; i < receivers.length; i++) {
                SplitsReceiver memory receiver = receivers[i];
                uint32 weight = receiver.weight;
                require(weight != 0, "Splits receiver weight is zero");
                totalWeight += weight;
                uint256 accountId = receiver.accountId;
                if (i > 0) require(prevAccountId < accountId, "Splits receivers not sorted");
                prevAccountId = accountId;
                emit SplitsReceiverSeen(receiversHash, accountId, weight);
            }
            require(totalWeight <= _TOTAL_SPLITS_WEIGHT, "Splits weights sum too high");
        }
    }

    /// @notice Asserts that the list of splits receivers is the account's currently used one.
    /// @param accountId The account ID.
    /// @param currReceivers The list of the account's current splits receivers.
    function _assertCurrSplits(uint256 accountId, SplitsReceiver[] memory currReceivers)
        internal
        view
    {
        require(
            _hashSplits(currReceivers) == _splitsHash(accountId), "Invalid current splits receivers"
        );
    }

    /// @notice Current account's splits hash, see `hashSplits`.
    /// @param accountId The account ID.
    /// @return currSplitsHash The current account's splits hash
    function _splitsHash(uint256 accountId) internal view returns (bytes32 currSplitsHash) {
        return _splitsStorage().splitsStates[accountId].splitsHash;
    }

    /// @notice Calculates the hash of the list of splits receivers.
    /// @param receivers The list of the splits receivers.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// @return receiversHash The hash of the list of splits receivers.
    function _hashSplits(SplitsReceiver[] memory receivers)
        internal
        pure
        returns (bytes32 receiversHash)
    {
        if (receivers.length == 0) {
            return bytes32(0);
        }
        return keccak256(abi.encode(receivers));
    }

    /// @notice Returns the Splits storage.
    /// @return splitsStorage The storage.
    function _splitsStorage() private view returns (SplitsStorage storage splitsStorage) {
        bytes32 slot = _splitsStorageSlot;
        // slither-disable-next-line assembly
        assembly {
            splitsStorage.slot := slot
        }
    }
}