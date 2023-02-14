// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract RolesManager is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
    bytes32 public constant AUTHORITY_ROLE = keccak256('AUTHORITY_ROLE');
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    /**
    * @notice Triggers stopped state.
    * @dev Could be called by pausers in case of resetting addresses.
    */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
    * @notice Returns to normal state.
    * @dev Could be called by pausers in case of resetting addresses.
    */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}