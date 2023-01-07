// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title Administered
 * @notice Implements Admin and User roles.
 */
contract SoftAdministered is Context {
    /// @dev Wallet Access Struct
    struct WalletAccessStruct {
        address wallet;
        bool active;
    }

    /// @dev Mapping of Wallet Acces
    mapping(address => WalletAccessStruct) _walletAddressAccessList;

    /// @dev Owner
    address private _owner;

    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the user.
     */
    modifier onlyUser() {
        require(hasRole(_msgSender()), "Ownable: caller is not the user");
        _;
    }

    /**
     * @dev Throws if called by any account other than the user or owner
     */
    modifier onlyUserOrOwner() {
        require(
            (owner() == _msgSender()) || hasRole(_msgSender()),
            "Ownable: caller is not valid"
        );
        _;
    }

    /// @dev Add `root` to the admin role as a member.
    function addRole(address _wallet) public virtual onlyOwner {
        if (!hasRole(_wallet)) {
            _walletAddressAccessList[_wallet] = WalletAccessStruct(
                _wallet,
                true
            );
        }
    }

    /// @dev Revoke user role
    function revokeRole(address _wallet) public virtual onlyOwner {
        if (hasRole(_wallet)) {
            _walletAddressAccessList[_wallet].active = false;
        }
    }

    /**
     * @dev Check if wallet address has already role
     */
    function hasRole(address _wallet) public view virtual returns (bool) {
        return _walletAddressAccessList[_wallet].active;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        _owner = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }
}