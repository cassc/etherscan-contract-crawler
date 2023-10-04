// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FrogoLocker {
    struct TimeLock {
        address token;
        uint256 releaseTime;
    }

    mapping(address => TimeLock) public timeLocks;

    address public immutable deployer;

    modifier onlyDeployer() {
        require(msg.sender == deployer, "onlyDeployer");
        _;
    }

    constructor() {
        deployer = msg.sender;
    }

    function addTimeLock(address _token, uint256 _releaseTime) public onlyDeployer {
        require(_releaseTime > block.timestamp, "release time is before current time");
        
        TimeLock storage timeLock = timeLocks[_token];
        require(timeLocks[_token].token == address(0), "TimeLock already exist for this token");

        timeLock.token = _token;
        timeLock.releaseTime = _releaseTime;
    }

    function increaseTimeLock(address _token, uint256 _releaseTime) public onlyDeployer {
        require(_releaseTime > block.timestamp, "release time is before current time");
        
        TimeLock storage timeLock = timeLocks[_token];
        require(timeLocks[_token].token == _token, "TimeLock not exist");
        require(_releaseTime > timeLock.releaseTime, "release time is before the current lock time");
        
        timeLock.releaseTime = _releaseTime;
    }

    function release(address _token) public onlyDeployer {
        TimeLock memory timeLock = timeLocks[_token];
        require(block.timestamp >= timeLock.releaseTime, "current time is before release time");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        require(amount > 0, "no tokens to release");

        IERC20(_token).transfer(deployer, amount);
    }

    function getTimeLock(address _token) external view returns (TimeLock memory) {
        return timeLocks[_token];
    }
}