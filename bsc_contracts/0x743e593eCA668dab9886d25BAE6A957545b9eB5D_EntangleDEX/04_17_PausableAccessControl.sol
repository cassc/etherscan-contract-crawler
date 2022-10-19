// SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


contract PausableAccessControl is AccessControl, Pausable  {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    function pause() onlyRole(PAUSER_ROLE) external {
        _pause();
    }

    function unpause() onlyRole(PAUSER_ROLE) external {
        _unpause();
    }
}