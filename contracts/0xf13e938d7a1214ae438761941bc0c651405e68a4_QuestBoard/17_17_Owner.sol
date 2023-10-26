// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../oz/utils/Ownable.sol";
import "../libraries/Errors.sol";

/** @title 2-step Ownership  */
/// @author Paladin
/*
    Extends OZ Ownable contract to add 2-step ownership transfer
*/

contract Owner is Ownable {

    address public pendingOwner;

    event NewPendingOwner(address indexed previousPendingOwner, address indexed newPendingOwner);

    function transferOwnership(address newOwner) public override virtual onlyOwner {
        if(newOwner == address(0)) revert Errors.AddressZero();
        if(newOwner == owner()) revert Errors.CannotBeOwner();
        address oldPendingOwner = pendingOwner;

        pendingOwner = newOwner;

        emit NewPendingOwner(oldPendingOwner, newOwner);
    }

    function acceptOwnership() public virtual {
        if(msg.sender != pendingOwner) revert Errors.CallerNotPendingOwner();
        address newOwner = pendingOwner;
        _transferOwnership(pendingOwner);
        pendingOwner = address(0);

        emit NewPendingOwner(newOwner, address(0));
    }

}