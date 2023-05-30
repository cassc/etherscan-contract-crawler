// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Pausable is Ownable {
    bool public pause;
    
    constructor() public {
        pause = false;
    }
    
    function setPauseStatus(bool _pauseStatus) public onlyOwner {
        pause = _pauseStatus;
    }
    
    modifier isPaused() {
        require(pause==false, "The system is paused");
        _;
    }
}