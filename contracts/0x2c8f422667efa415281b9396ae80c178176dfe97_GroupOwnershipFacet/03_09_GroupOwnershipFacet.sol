//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IOwnership} from "../../interfaces/IOwnership.sol";
import {LibOwnership} from "../../libraries/LibOwnership.sol";

/// @author Amit Molek
/// @dev Please see `IOwnership` for docs
contract GroupOwnershipFacet is IOwnership {
    function ownershipUnits(address member)
        external
        view
        override
        returns (uint256)
    {
        return LibOwnership._ownershipUnits(member);
    }

    function totalOwnershipUnits() external view override returns (uint256) {
        return LibOwnership._totalOwnershipUnits();
    }

    function totalOwnedOwnershipUnits()
        external
        view
        override
        returns (uint256)
    {
        return LibOwnership._totalOwnedOwnershipUnits();
    }

    function isCompletelyOwned() external view override returns (bool) {
        return LibOwnership._isCompletelyOwned();
    }

    function smallestOwnershipUnit() external view override returns (uint256) {
        return LibOwnership._smallestUnit();
    }

    function isMember(address account) external view override returns (bool) {
        return LibOwnership._isMember(account);
    }

    function members() external view override returns (address[] memory) {
        return LibOwnership._members();
    }

    function memberAt(uint256 index)
        external
        view
        override
        returns (address, uint256)
    {
        return LibOwnership._memberAt(index);
    }

    function memberCount() external view override returns (uint256) {
        return LibOwnership._memberCount();
    }
}