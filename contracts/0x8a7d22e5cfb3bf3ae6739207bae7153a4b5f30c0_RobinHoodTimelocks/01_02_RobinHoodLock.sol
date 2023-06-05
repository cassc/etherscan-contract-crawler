// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract RobinHoodTimelocks {
    struct Lock {
        address beneficiary;
        uint256 releaseTime;
    }

    mapping(address => Lock) locks;

    function addLock(address _token, address _beneficiary, uint256 _releaseTime) external {
        require(_releaseTime > block.timestamp, "release time is before current time");
        locks[_token] = Lock({
            beneficiary: _beneficiary,
            releaseTime: _releaseTime
        });
       
    }

    function release(address _token) external {
        Lock memory lock = locks[_token];
        require(block.timestamp >= lock.releaseTime, "current time is before release time");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        require(amount > 0, "no tokens to release");

        IERC20(_token).transfer(lock.beneficiary, amount);
    }
}