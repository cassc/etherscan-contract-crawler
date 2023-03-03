// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

error InsufficientAccess();
error InvalidOwner();

abstract contract Administration is AccessControl, Pausable {
    address private _owner;

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant MINTER = keccak256("MINTER");

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier isAdmin() {
        if (!hasRole(ADMIN, _msgSender())) {
            revert InsufficientAccess();
        }
        _;
    }

    modifier isMinter() {
        if (!hasRole(MINTER, _msgSender())) {
            revert InsufficientAccess();
        }
        _;
    }

    modifier isGlobalAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert InsufficientAccess();
        }
        _;
    }

    constructor(address globalAdmin) {
        _setupRole(MINTER, _msgSender());
        _setupRole(ADMIN, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, globalAdmin);
        _setupRole(ADMIN, globalAdmin);
        _setOwner(globalAdmin);
    }

    function pause() public isAdmin {
        _pause();
    }

    function unpause() public isAdmin {
        _unpause();
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual isAdmin {
        if (newOwner == address(0)) revert InvalidOwner();
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl) returns (bool) {
        return
            interfaceId == type(AccessControl).interfaceId ||
            interfaceId == type(Pausable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}