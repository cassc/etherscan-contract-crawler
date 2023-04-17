/**
 *Submitted for verification at Etherscan.io on 2023-04-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract LPLocker {
    struct LockedToken {
        address token;
        uint256 amount;
        uint256 unlockDate;
        address withdrawer;
    }

    uint256 public lockCount;
    mapping(uint256 => LockedToken) public lockedTokens;

    event Lock(uint256 indexed lockId, address indexed token, uint256 amount, uint256 unlockDate, address withdrawer);

    function lockLPtoken(address _token, uint256 _amount, uint256 _unlock_date, address _withdrawer) external {
        require(_token != address(0), "LPLocker: Invalid token address");
        require(_amount > 0, "LPLocker: Amount must be greater than 0");
        require(_unlock_date > block.timestamp, "LPLocker: Unlock date must be in the future");
        require(_withdrawer != address(0), "LPLocker: Invalid withdrawer address");

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        lockedTokens[lockCount] = LockedToken(_token, _amount, _unlock_date, _withdrawer);
        emit Lock(lockCount, _token, _amount, _unlock_date, _withdrawer);

        lockCount++;
    }

    function withdraw(uint256 lockId) external {
        LockedToken storage lockedToken = lockedTokens[lockId];
        require(lockedToken.withdrawer == msg.sender, "LPLocker: Only withdrawer can unlock the tokens");

        IERC20(lockedToken.token).transfer(lockedToken.withdrawer, lockedToken.amount);

        delete lockedTokens[lockId];
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}