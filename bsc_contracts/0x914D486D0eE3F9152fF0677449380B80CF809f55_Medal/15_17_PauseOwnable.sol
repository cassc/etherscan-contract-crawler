// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-v0.8/security/Pausable.sol";
import "@openzeppelin/contracts-v0.8/access/Ownable.sol";

abstract contract PauseOwnable is Pausable, Ownable {
    /**
     * @dev triggers stopped state.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev returns to normal state.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}