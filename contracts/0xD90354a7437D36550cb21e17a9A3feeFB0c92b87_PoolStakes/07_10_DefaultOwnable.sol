// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * Inspired and borrowed by/from the openzeppelin/contracts` {Ownable}.
 * Unlike openzeppelin` version:
 * - by default, the owner account is the one returned by the {_defaultOwner}
 * function, but not the deployer address;
 * - this contract has no constructor and may run w/o initialization;
 * - the {renounceOwnership} function removed.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 * The child contract must define the {_defaultOwner} function.
 */
abstract contract DefaultOwnable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev Returns the current owner address, if it's defined, or the default owner address otherwise.
    function owner() public view virtual returns (address) {
        return _owner == address(0) ? _defaultOwner() : _owner;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /// @dev Transfers ownership of the contract to the `newOwner`. The owner can only call.
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function _defaultOwner() internal view virtual returns (address);
}