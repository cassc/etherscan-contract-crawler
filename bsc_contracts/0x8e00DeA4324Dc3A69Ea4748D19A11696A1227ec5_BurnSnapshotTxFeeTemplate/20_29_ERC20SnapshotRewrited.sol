// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20Base.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol";

import "../utils/ArrayStorageSlot.sol";
import "../utils/MappingStorageSlot.sol";

/**
 * This is a rewrite from OZ Contratcs to use the StorageSlot Library funcionalities, even with arrays and mappings. Enjoy!

 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the begining of each new block. When overridding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20SnapshotRewrited is ERC20Base {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol


    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    bytes32 internal constant SLOT_TOTAL_SUPPLY_SNAPSHOTST_IDS= keccak256("polkalokr.oz.token.erc20.extensions.erc20snapshot.snapshots.ids");
    bytes32 internal constant SLOT_TOTAL_SUPPLY_SNAPSHOTST_VALUES= keccak256("polkalokr.oz.token.erc20.extensions.erc20snapshot.snapshots.values");

    bytes32 internal constant ACCOUNT_BALANCE_SNAPSHOTS_SLOT = keccak256("polkalokr.oz.token.erc20.extensions.erc20snapshot._accountBalanceSnapshots");
    
    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    bytes32 internal constant CURRENT_SNAPSHOT_ID= keccak256("polkalokr.oz.token.erc20.extensions.erc20snapshot._currentSnapshotId");


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
        StorageSlotUpgradeable.getUint256Slot(CURRENT_SNAPSHOT_ID).value +=1;

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return StorageSlotUpgradeable.getUint256Slot(CURRENT_SNAPSHOT_ID).value;
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        bytes32 slotIds = keccak256(abi.encode(account, ACCOUNT_BALANCE_SNAPSHOTS_SLOT));
        bytes32 slotValues = bytes32(uint256(slotIds) + 1);
        (bool snapshotted, uint256 value) = 
            _valueAt(snapshotId, slotIds, slotValues);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = 
            _valueAt(snapshotId, SLOT_TOTAL_SUPPLY_SNAPSHOTST_IDS, SLOT_TOTAL_SUPPLY_SNAPSHOTST_VALUES);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, bytes32 slotIds, bytes32 slotValues) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");
        /*
            When a valid snapshot is queried, there are three possibilities:
             a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
             created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
             to this id is the current one.
             b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
             requested id, and its value is the one to return.
             c) More snapshots were created after the requested one, and the queried value was later modified. There will be
             no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
             larger than the requested one.
        
            In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
            it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
            exactly this.
        */
        uint index = _findUpperBound(slotIds, snapshotId);

        if (index == ArrayStorageSlot.length(slotIds).value) {
            return (false, 0);
        } else {
            
            return (true, ArrayStorageSlot.getUint256Slot(slotValues, index).value);
        }
    }

    function _updateAccountSnapshot(address account) private {
        bytes32 slotIds = keccak256(abi.encode(account, ACCOUNT_BALANCE_SNAPSHOTS_SLOT));
        bytes32 slotValues = bytes32(uint256(slotIds) + 1);
        _updateSnapshot(slotIds, slotValues, balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(SLOT_TOTAL_SUPPLY_SNAPSHOTST_IDS, SLOT_TOTAL_SUPPLY_SNAPSHOTST_VALUES, totalSupply());
    }

    function _updateSnapshot(bytes32 _slotIds, bytes32 _slotValues, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(_slotIds) < currentId) {
            ArrayStorageSlot.push(_slotIds, currentId);
            ArrayStorageSlot.push(_slotValues, currentValue);
        }
    }

    function _lastSnapshotId(bytes32 slotIds) private view returns (uint256) {
        uint idsLength = ArrayStorageSlot.length(slotIds).value;
        if (idsLength == 0) {
            return 0;
        } else {
            return ArrayStorageSlot.getUint256Slot(slotIds, idsLength - 1).value;
        }
    }
    
    function _findUpperBound(bytes32 slot, uint element) private view returns (uint256){
        uint256 low = 0;
        uint256 high = ArrayStorageSlot.length(slot).value;
        if (high == 0) {
            return 0;
        }
        
        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (ArrayStorageSlot.getUint256Slot(slot, mid).value > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && ArrayStorageSlot.getUint256Slot(slot, low - 1).value == element) {
            return low - 1;
        } else {
            return low;
        }

    }
}