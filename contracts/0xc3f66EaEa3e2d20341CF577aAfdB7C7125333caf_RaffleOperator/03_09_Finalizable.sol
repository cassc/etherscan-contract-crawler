// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./Owned.sol";

contract Finalizable is Owned {
    bool public running;

    event LogRunSwitch(address sender, bool switchSetting);

    modifier onlyIfRunning() {
        require(running, "Is not running.");
        _;
    }

    modifier onlyIfNotRunning() {
        require(!running, "Is still running.");
        _;
    }

    constructor() {
        running = true;
    }

    function runSwitch(bool onOff)
        external
        onlyOwner
        onlyIfRunning
        returns (bool success)
    {
        running = onOff;
        emit LogRunSwitch(msg.sender, onOff);
        return true;
    }
}
