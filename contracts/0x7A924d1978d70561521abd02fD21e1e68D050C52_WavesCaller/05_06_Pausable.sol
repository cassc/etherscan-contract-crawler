// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Adminable.sol";

abstract contract Pausable is Adminable {
    event Paused(address account);
    event Unpaused(address account);
    event PauserUpdated(address sender, address oldPauser, address pauser);

    bool public isPaused;
    address public pauser;

    constructor() {
        isPaused = false;
    }

    modifier whenNotPaused() {
        require(!isPaused, "paused");
        _;
    }

    modifier whenPaused() {
        require(isPaused, "not paused");
        _;
    }

    modifier onlyPauser() {
        require(pauser == msg.sender, "only pauser");
        _;
    }

    function pause() external whenNotPaused onlyPauser {
        isPaused = true;
        emit Paused(msg.sender);
    }

    function unpause() external whenPaused onlyPauser {
        isPaused = false;
        emit Unpaused(msg.sender);
    }

    function updatePauser(address pauser_) external onlyAdmin {
        require(pauser_ != address(0), "zero address");
        emit PauserUpdated(msg.sender, pauser, pauser_);
        pauser = pauser_;
    }
}