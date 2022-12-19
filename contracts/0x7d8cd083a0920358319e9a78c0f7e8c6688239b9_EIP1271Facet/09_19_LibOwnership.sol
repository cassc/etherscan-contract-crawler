//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StorageOwnershipUnits} from "../storage/StorageOwnershipUnits.sol";
import {LibState} from "../libraries/LibState.sol";
import {StateEnum} from "../structs/StateEnum.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

/// @author Amit Molek
/// @dev Please see `IOwnership` for docs
library LibOwnership {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    /// @notice Adds `account` as an onwer
    /// @dev For internal use only
    /// You must call this function with join's deposit value attached
    function _addOwner(address account, uint256 ownershipUnits) internal {
        // Verify that the group is still open
        LibState._stateGuard(StateEnum.OPEN);

        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        // Update the member's ownership units
        require(
            ds.ownershipUnits.set(account, ownershipUnits),
            "Ownership: existing member"
        );

        // Verify ownership deposit is valid
        _depositGuard(ownershipUnits);

        // Update the total ownership units owned
        ds.totalOwnedOwnershipUnits += ownershipUnits;
    }

    /// @notice `account` acquires more ownership units
    /// @dev You must call this with value attached
    function _acquireMoreOwnershipUnits(address account, uint256 ownershipUnits)
        internal
    {
        // Verify that the group is still open
        LibState._stateGuard(StateEnum.OPEN);

        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        // Only existing member can obtain more units
        require(ds.ownershipUnits.contains(account), "Ownership: not a member");

        // Verify ownership deposit is valid
        _depositGuard(ownershipUnits);

        uint256 currentOwnerUnits = ds.ownershipUnits.get(account);
        ds.ownershipUnits.set(account, currentOwnerUnits + ownershipUnits);
        ds.totalOwnedOwnershipUnits += ownershipUnits;
    }

    /// @dev Guard that verifies that the ownership deposit is valid
    /// Can revert:
    ///     - "Ownership: deposit not divisible by smallest unit"
    ///     - "Ownership: deposit exceeds total ownership units"
    ///     - "Ownership: deposit must be bigger than 0"
    function _depositGuard(uint256 ownershipUnits) internal {
        uint256 value = msg.value;
        uint256 smallestUnit = _smallestUnit();

        require(
            value >= ownershipUnits,
            "Ownership: mismatch between units and deposit amount"
        );

        require(ownershipUnits > 0, "Ownership: deposit must be bigger than 0");

        require(
            ownershipUnits % smallestUnit == 0,
            "Ownership: deposit not divisible by smallest unit"
        );

        require(
            ownershipUnits + _totalOwnedOwnershipUnits() <=
                _totalOwnershipUnits(),
            "Ownership: deposit exceeds total ownership units"
        );
    }

    /// @notice Renounce ownership
    /// @dev The caller renounce his ownership
    /// @return refund the amount to refund to the caller
    function _renounceOwnership() internal returns (uint256 refund) {
        // Verify that the group is still open
        require(
            LibState._state() == StateEnum.OPEN,
            "Ownership: group formed or uninitialized"
        );

        // Verify that the caller is a member
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        require(
            ds.ownershipUnits.contains(msg.sender),
            "Ownership: not an owner"
        );

        // Update the member ownership units and the total units owned
        refund = ds.ownershipUnits.get(msg.sender);
        ds.totalOwnedOwnershipUnits -= refund;
        ds.ownershipUnits.remove(msg.sender);
    }

    function _ownershipUnits(address member) internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.ownershipUnits.get(member);
    }

    function _totalOwnershipUnits() internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.totalOwnershipUnits;
    }

    function _smallestUnit() internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.smallestOwnershipUnit;
    }

    function _totalOwnedOwnershipUnits() internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.totalOwnedOwnershipUnits;
    }

    function _isCompletelyOwned() internal view returns (bool) {
        return _totalOwnedOwnershipUnits() == _totalOwnershipUnits();
    }

    function _isMember(address account) internal view returns (bool) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.ownershipUnits.contains(account);
    }

    function _memberAt(uint256 index)
        internal
        view
        returns (address member, uint256 units)
    {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        (member, units) = ds.ownershipUnits.at(index);
    }

    function _memberCount() internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.ownershipUnits.length();
    }

    function _members() internal view returns (address[] memory members) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        uint256 length = ds.ownershipUnits.length();
        members = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            (members[i], ) = ds.ownershipUnits.at(i);
        }
    }
}