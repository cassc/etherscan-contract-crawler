// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../open-zeppelin/utils/Ownable.sol";

/** @title Extend OZ Ownable contract  */
/// @author Paladin

contract Owner is Ownable {

    address public pendingOwner;

    event NewPendingOwner(address indexed previousPendingOwner, address indexed newPendingOwner);

    error CannotBeOwner();
    error CallerNotPendingOwner();
    error ZeroAddress();

    function transferOwnership(address newOwner) public override virtual onlyOwner {
        if(newOwner == address(0)) revert ZeroAddress();
        if(newOwner == owner()) revert CannotBeOwner();
        address oldPendingOwner = pendingOwner;

        pendingOwner = newOwner;

        emit NewPendingOwner(oldPendingOwner, newOwner);
    }

    function acceptOwnership() public virtual {
        if(pendingOwner == address(0)) revert ZeroAddress();
        if(msg.sender != pendingOwner) revert CallerNotPendingOwner();
        address newOwner = pendingOwner;
        _transferOwnership(pendingOwner);
        pendingOwner = address(0);

        emit NewPendingOwner(newOwner, address(0));
    }

}