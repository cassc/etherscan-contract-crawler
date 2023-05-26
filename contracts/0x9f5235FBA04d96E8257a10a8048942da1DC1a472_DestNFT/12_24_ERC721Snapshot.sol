// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract ERC721Snapshot is ERC721 {
    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct SnapshotsBalances {
        uint256[] ids;
        uint256[] values;
    }

    struct SnapshotsOwners {
        uint256[] ids;
        address[] addresses;
    }

    mapping(address => SnapshotsBalances) private _accountBalanceSnapshots;
    mapping(uint256 => SnapshotsOwners) private _accountOwnersSnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    function ownerOfAt(uint256 tokenId, uint256 snapshotId) public view virtual returns (address) {
        (bool snapshotted, address addr) = _ownerAt(snapshotId, _accountOwnersSnapshots[tokenId]);

        return snapshotted ? addr : address(0);
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to, tokenId, 1);
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from, tokenId, -1);
        } else {
            // transfer
            _updateAccountSnapshot(from, tokenId, -1);
            _updateAccountSnapshot(to, tokenId, 1);
        }
    }

    function _valueAt(uint256 snapshotId, SnapshotsBalances storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC721Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC721Snapshot: nonexistent id");

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _ownerAt(uint256 snapshotId, SnapshotsOwners storage snapshots) private view returns (bool, address) {
        require(snapshotId > 0, "ERC721Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC721Snapshot: nonexistent id");

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, address(0));
        } else {
            return (true, snapshots.addresses[index]);
        }
    }

    function _updateAccountSnapshot(address account, uint256 tokenId, int8 amount) private {
        _updateSnapshotBalance(_accountBalanceSnapshots[account], uint256(int256(super.balanceOf(account)) + amount));
        _updateSnapshotOwner(_accountOwnersSnapshots[tokenId], amount > 0 ? account : address(0));
    }

    function _updateSnapshotBalance(SnapshotsBalances storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        } else if ( snapshots.values.length > 0 ) {
            snapshots.values[ snapshots.values.length - 1 ] = currentValue;
        }
    }

    function _updateSnapshotOwner(SnapshotsOwners storage snapshots, address currentOwner) private {
        uint256 currentId = _getCurrentSnapshotId();
        uint256 lastId = _lastSnapshotId(snapshots.ids);
        if (lastId < currentId) {
            snapshots.ids.push(currentId);
            snapshots.addresses.push(currentOwner);
        } else if ( snapshots.addresses.length > 0 ) {
            snapshots.addresses[ snapshots.addresses.length - 1 ] = currentOwner;
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}