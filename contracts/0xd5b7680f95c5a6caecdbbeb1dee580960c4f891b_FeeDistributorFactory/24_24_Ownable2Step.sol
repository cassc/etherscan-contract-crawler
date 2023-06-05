// SPDX-FileCopyrightText: 2023 P2P Validator <[email protected]>, OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Ownable.sol";

/**
* @notice caller must be pendingOwner
*/
error Ownable2Step__CallerNotNewOwner();

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private s_pendingOwner;

    /**
     * @dev Emits in transferOwnership (start of the transfer)
     * @param _previousOwner address of the previous owner
     * @param _newOwner address of the new owner
     */
    event OwnershipTransferStarted(address indexed _previousOwner, address indexed _newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return s_pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        s_pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete s_pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert Ownable2Step__CallerNotNewOwner();
        }
        _transferOwnership(sender);
    }
}