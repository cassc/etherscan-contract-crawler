pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

contract MintAdmin is AccessControl, Pausable {
    bytes32 public constant ADMIN = keccak256('ADMIN');
    bytes32 public constant MINTER = keccak256('Minter');
    bytes32 public constant SIGNER = keccak256('SIGNER');

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

    function pause() public isGlobalAdmin {
        _pause();
    }

    function unpause() public isGlobalAdmin {
        _unpause();
    }

    constructor(address globalAdmin) {
        _setupRole(DEFAULT_ADMIN_ROLE, globalAdmin);
        _setupRole(ADMIN, globalAdmin);
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, SIGNER);
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, ADMIN);
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, MINTER);
    }
}