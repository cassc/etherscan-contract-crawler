// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/IOwnablePausableEvents.sol";

contract OwnablePausable is Ownable, Pausable, IOwnablePausableEvents {
    function toggle() external {
        _checkOwner();
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
        emit PauseStateSet(paused());
    }

    function _requireNotPaused() internal view virtual override {
        require(!paused(), "Contract Paused");
    }
}