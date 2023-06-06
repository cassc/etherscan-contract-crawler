// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../oz/utils/Ownable.sol";

/** @title 2-step Ownership  */
/// @author Paladin
/*
    Extends OZ Ownable contract to add 2-step ownership transfer
*/

contract Owner is Ownable {

    address public pendingOwner;

    event NewPendingOwner(address indexed previousPendingOwner, address indexed newPendingOwner);

    error CallerNotPendingOwner();
    error CannotBeOwner();
    error AddressZero();

    function transferOwnership(address newOwner) public override virtual onlyOwner {
        if(newOwner == address(0)) revert AddressZero();
        if(newOwner == owner()) revert CannotBeOwner();
        address oldPendingOwner = pendingOwner;

        pendingOwner = newOwner;

        emit NewPendingOwner(oldPendingOwner, newOwner);
    }

    function acceptOwnership() public virtual {
        if(msg.sender != pendingOwner) revert CallerNotPendingOwner();
        address newOwner = pendingOwner;
        _transferOwnership(pendingOwner);
        pendingOwner = address(0);

        emit NewPendingOwner(newOwner, address(0));
    }

}