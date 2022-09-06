// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "./Ownable.sol";

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused external {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused external {
        paused = false;
        emit Unpause();
    }
}