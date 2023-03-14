// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

abstract contract PauserAccess is AccessControl, Pausable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    modifier onlyPausers() {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Access: pauser role required");
        _;
    }

    /**
     * @dev Pauses all token transfers.
     */
    function pause() public virtual onlyPausers {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     */
    function unpause() public virtual onlyPausers {
        _unpause();
    }
}