// SPDX-FileCopyrightText: 2022 P2P Validator <[email protected]>, OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./OwnableBase.sol";

/**
* @notice _newOwner cannot be a zero address
*/
error Ownable__NewOwnerIsZeroAddress();

/**
 * @dev OpenZeppelin's Ownable with modifier onlyOwner extracted to OwnableBase
 * and removed `renounceOwnership`
 */
abstract contract Ownable is OwnableBase {

    /**
     * @dev Emits when the owner has been changed.
     * @param _previousOwner address of the previous owner
     * @param _newOwner address of the new owner
     */
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    address private s_owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual override returns (address) {
        return s_owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * @param _newOwner address of the new owner
     */
    function transferOwnership(address _newOwner) external virtual onlyOwner {
        if (_newOwner == address(0)) {
            revert Ownable__NewOwnerIsZeroAddress();
        }
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     * @param _newOwner address of the new owner
     */
    function _transferOwnership(address _newOwner) internal virtual {
        address oldOwner = s_owner;
        s_owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
}