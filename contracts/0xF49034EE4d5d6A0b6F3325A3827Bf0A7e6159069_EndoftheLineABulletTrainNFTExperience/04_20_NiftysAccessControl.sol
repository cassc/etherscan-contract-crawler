// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

abstract contract NiftysAccessControl is AccessControl, Pausable {
    address private _owner;

    bytes32 public constant ADMIN = keccak256('ADMIN');
    bytes32 public constant MINTER = keccak256('Minter');
    bytes32 public constant SIGNER = keccak256('SIGNER');

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier isAdmin() {
        require(hasRole(ADMIN, _msgSender()), 'sender must have the ADMIN role');
        _;
    }

    modifier isMinter() {
        require(hasRole(MINTER, _msgSender()), 'sender must have the MINT role');
        _;
    }

    modifier isGlobalAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            'sender must hae the DEFAULT ADMIN ROLE'
        );
        _;
    }

    constructor(address globalAdmin) {
        if (_msgSender() != globalAdmin) {
            _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
            _setupRole(ADMIN, _msgSender());
        }
        _setupRole(DEFAULT_ADMIN_ROLE, globalAdmin);
        _setupRole(ADMIN, globalAdmin);

        _setOwner(_msgSender());
    }

    function pause() public isGlobalAdmin {
        _pause();
    }

    function unpause() public isGlobalAdmin {
        _unpause();
    }

    /**
     * @dev Ownership is
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual isAdmin {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(AccessControl).interfaceId ||
            interfaceId == type(Pausable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}