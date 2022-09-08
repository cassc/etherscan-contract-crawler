pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

contract Admin is AccessControl, Pausable {
    bytes32 public constant ADMIN = keccak256('ADMIN');

    bytes32 public constant SIGNER = keccak256('SIGNER');

    modifier isAdmin() {
        require(hasRole(ADMIN, _msgSender()), 'sender must have the ADMIN role');
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
    }
}