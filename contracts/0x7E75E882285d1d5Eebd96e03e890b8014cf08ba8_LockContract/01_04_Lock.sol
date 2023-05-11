// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract LockContract is Ownable {
    uint256 public unlockTime;

    constructor(uint256 _unlockTime) {
        unlockTime = _unlockTime;
    }

    function lock(address lp, uint256 amount) public {
        IERC20(lp).transferFrom(msg.sender, address(this), amount);
    }

    function extendLock(uint256 _unlockTime) public onlyOwner {
        require(_unlockTime > unlockTime, "New unlock time must be greater than current unlock time.");
        unlockTime = _unlockTime;
    }

    function withdraw(address lp, uint256 amount) public onlyOwner {
        require(block.timestamp >= unlockTime, "Lock period has not ended yet.");
        IERC20(lp).transfer(msg.sender, amount);
    }
}