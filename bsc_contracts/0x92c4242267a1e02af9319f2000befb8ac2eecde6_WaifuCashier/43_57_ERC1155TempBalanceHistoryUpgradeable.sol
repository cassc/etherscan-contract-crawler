// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ArraysUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @dev This contract's logic is based on OpenZeppelin ERC20Snapshot and
 * extends an ERC1155 contract with a snapshot mechanism. When a snapshot is
 * created, the balances at the time are recorded for later access.
 *
 * Unlike the snapshot contract, balances history for a snapshot range can be
 * queried, and history can be cleared when it's no longer needed.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit
 * the {Snapshot} event and return a snapshot id. To get the aggregate supply
 * at the time of a snapshot, call the function {aggregateSupplyAt} with the
 * snapshot id. To get the token id balance of an account at the time of a
 * snapshot, call the {balanceOfAt} function with the snapshot id, token id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the
 * {getCurrentSnapshotId} method. For example, having it return `block.number`
 * will trigger the creation of snapshot at the beginning of each new block.
 * When overriding this function, be careful about the monotonicity of its
 * result. Non-monotonic snapshot ids will break the contract.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances
 *  from a snapshot is _O(log n)_ in the number of snapshots that have been
 * created, although _n_ for a specific account will generally be much smaller
 * since identical balances in subsequent snapshots are stored as a single
 * entry.
 *
 * There is a constant overhead for normal ERC1155 transfers due to the
 * additional snapshot bookkeeping. This overhead is only significant for the
 * first transfer that immediately follows a snapshot for a particular account.
 * Subsequent transfers will have normal cost until the next snapshot, and so
 * on.
 */
abstract contract ERC1155TempBalanceHistoryUpgradeable is
    Initializable,
    ERC1155Upgradeable,
    PausableUpgradeable
{
    function __ERC1155TempBalanceHistory_init()
        internal
        onlyInitializing
    {
        __ERC1155TempBalanceHistory_init_unchained();
    }

    function __ERC1155TempBalanceHistory_init_unchained()
        internal
        onlyInitializing
    {}

    using ArraysUpgradeable for uint256[];
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /*
     * Snapshotted values have arrays of ids and the value corresponding to
     * that id. These could be an array of a Snapshot struct, but that would
     * impede usage of functions that work on an array.
     */
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    struct BalanceRecord {
        uint256 balance;
        uint256 tillSnapshot;
    }

    mapping(
        address => mapping(uint256 => Snapshots)
    ) private _accountBalanceSnapshots;

    mapping(address => uint256) public historyLastCleared;

    /*
     * Snapshot ids increase monotonically, with the first value being 1.
     * An id of 0 is invalid.
     */
    CountersUpgradeable.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when an `id` snapshot is created.
     */
    event Snapshot(uint256 id);
    event HistoryCleared(address account);

    function getCurrentSnapshotId() public view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Returns `tokenId` balance history of `account` for the period from
     * `fromSnapshot` to `toSnapshot`.
     */
    function getBalanceHistoryOf(
        address account,
        uint256 tokenId,
        uint256 fromSnapshot,
        uint256 toSnapshot
    ) public view returns (BalanceRecord[] memory balanceHistory) {
        require(fromSnapshot <= toSnapshot, "ERC1155Snapshot: invalid range");
        require(
            fromSnapshot > historyLastCleared[account],
            "ERC1155Snapshot: record deleted"
        );
        require(
            toSnapshot <= getCurrentSnapshotId(),
            "ERC1155Snapshot: nonexistent id"
        );

        Snapshots storage snapshots =
            _accountBalanceSnapshots[account][tokenId];

        uint256 fromIndex = _findSnapshotId(account, tokenId, fromSnapshot);

        if (fromIndex == snapshots.ids.length) {
            // no snapshots saved for requested period, return current balance
            balanceHistory = new BalanceRecord[](1);
            balanceHistory[0] =
                BalanceRecord(balanceOf(account, tokenId), toSnapshot);
            return balanceHistory;
        }

        // inclusive, but can go out of bounds if snapshot hasn't been saved,
        // that's taken into account a few lines below
        uint256 toIndex = _findSnapshotId(account, tokenId, toSnapshot);

        uint256 historyLength = toIndex - fromIndex + 1;
        balanceHistory = new BalanceRecord[](historyLength);

        if (toIndex == snapshots.ids.length) {
            // balance hasn't changed since toSnapshot, and snapshot hasn't
            // been saved, we need to add last record manually
            balanceHistory[historyLength - 1] =
                BalanceRecord(balanceOf(account, tokenId), toSnapshot);
            toIndex--;
        }
        uint256 historyIndex = 0;
        for (uint256 i = fromIndex; i <= toIndex; i++) {
            balanceHistory[historyIndex++] =
                BalanceRecord(snapshots.values[i], snapshots.ids[i]);
        }

        // last snapshot id can go out of requested bounds, let's fix it
        balanceHistory[historyLength - 1].tillSnapshot = toSnapshot;
    }

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it
     * externally. Its usage may be restricted to a set of accounts, for
     * example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust
     * minimization mechanisms such as forking, you must consider that it can
     * potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from
     * snapshots, although it will grow logarithmically thus rendering this
     * attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them,
     * in the ways specified in the Gas Costs section above.
     *
     * We haven't measured the actual numbers; if this is something you're
     * interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentSnapshotId = getCurrentSnapshotId();
        emit Snapshot(currentSnapshotId);
        return currentSnapshotId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Find first saved `account` `tokenId` balance snapshot with id
     * greater than `snapshotId`, or the array length if no such snapshot found,
     * similar to ArraysUpgradeable.findUpperBound, but with quick paths for
     * common querries.
     */
    function _findSnapshotId(
        address account,
        uint256 tokenId,
        uint256 snapshotId
    ) private view returns (uint256 index) {
        Snapshots storage snapshots =
            _accountBalanceSnapshots[account][tokenId];
        uint256 snapshotsLength = snapshots.ids.length;
        if (snapshotsLength == 0) {
            // no snapshots found, return length
            return 0;
        }
        if (snapshotId == historyLastCleared[account] + 1) {
            // fisrt saved snapshot
            return 0;
        }
        uint256 currentSnapshotId = getCurrentSnapshotId();
        if (snapshotId == currentSnapshotId) {
            // either last saved snapshot, or not saved yet
            if (snapshots.ids[snapshotsLength - 1] == currentSnapshotId) {
                return snapshotsLength - 1;
            } else {
                return snapshotsLength;
            }
        }

        return snapshots.ids.findUpperBound(snapshotId);
    }

    /*
     * Designed for contracts with continously incremented token IDs, override
     * for different kind of contracts.
     */
    function _clearHistoryFor(address account) internal virtual whenNotPaused {
        uint256 lastTokenId = _getLastTokenId();

        for (uint256 i = 0; i <= lastTokenId; i++) {
            delete _accountBalanceSnapshots[account][i];
        }

        historyLastCleared[account] = getCurrentSnapshotId();

        emit HistoryCleared(account);
    }

    function _getLastTokenId() internal virtual returns (uint256);

    /* 
     * Update collection balance snapshots before the values are modified.
     * This is implemented in the _beforeTokenTransfer hook, which is executed
     * for _mint, _burn, and _transfer operations.
     */ 
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        if (from == address(0)) {
            // mint
            _updateAccountSnapshots(to, ids);
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshots(from, ids);
        } else {
            // transfer
            _doubleUpdateAccountSnapshots(from, to, ids);
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _updateAccountSnapshots(
            address account,
            uint256[] memory tokenIds
    ) private {
        uint256 currentSnapshotId = getCurrentSnapshotId();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _updateAccountSnapshot(currentSnapshotId, tokenIds[i], account);
        }
    }

    function _doubleUpdateAccountSnapshots(
        address account1,
        address account2,
        uint256[] memory tokenIds
    ) private {
        uint256 currentSnapshotId = getCurrentSnapshotId();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _updateAccountSnapshot(currentSnapshotId, tokenIds[i], account1);
            _updateAccountSnapshot(currentSnapshotId, tokenIds[i], account2);
        }
    }

    function _updateAccountSnapshot(
        uint256 currentSnapshotId,
        uint256 tokenId,
        address account
    ) private {
        // don't save cleared snapshot
        if (historyLastCleared[account] == currentSnapshotId) {
            return;
        }

        _updateSnapshot(
            _accountBalanceSnapshots[account][tokenId],
            currentSnapshotId,
            balanceOf(account, tokenId)
        );
    }

    function _updateSnapshot(
        Snapshots storage snapshots,
        uint256 currentSnapshotId,
        uint256 currentValue
    ) private {
        if (_lastSnapshotId(snapshots.ids) < currentSnapshotId) {
            snapshots.ids.push(currentSnapshotId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids)
        private
        view
        returns (uint256)
    {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}