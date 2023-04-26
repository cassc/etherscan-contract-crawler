/**
 *Submitted for verification at Etherscan.io on 2023-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TimeLockedDeposit {
    struct Deposit {
        address tokenAddress;
        uint256 amount;
        address depositor;
        address withdrawer;
        uint256 unlockTime;
    }

    struct WithdrawSchedule {
        uint256 depositId;
        uint256 unlockTime;
        uint256 amount;
    }

    mapping(address => mapping(uint256 => Deposit)) public deposits;
    mapping(address => uint256) private depositCounters;

    event DepositCreated(address indexed depositor, uint256 depositId, address indexed tokenAddress, uint256 amount, address indexed withdrawer, uint256 unlockTime);
    event Withdrawn(address indexed depositor, uint256 depositId, address indexed withdrawer, uint256 amount);

    function createDeposit(
        address _tokenAddress,
        uint256 _amount,
        address _withdrawer,
        uint256 _minutesToUnlock
    ) external {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_amount > 0, "Amount must be greater than 0");
        require(_withdrawer != address(0), "Invalid withdrawer address");

        IERC20 token = IERC20(_tokenAddress);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Token allowance is insufficient");

        uint256 initialBalance = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), _amount);
        uint256 newBalance = token.balanceOf(address(this));

        require(newBalance == initialBalance + _amount, "Transfer was not completed correctly");

        uint256 unlockTime = block.timestamp + _minutesToUnlock * 1 minutes;
        uint256 depositId = depositCounters[msg.sender]++;
        deposits[msg.sender][depositId] = Deposit(_tokenAddress, _amount, msg.sender, _withdrawer, unlockTime);

        emit DepositCreated(msg.sender, depositId, _tokenAddress, _amount, _withdrawer, unlockTime);
    }

    function withdraw(uint256 _depositId) external {
        Deposit storage deposit = deposits[msg.sender][_depositId];

        require(deposit.withdrawer == msg.sender, "Only the designated withdrawer can withdraw");
        require(block.timestamp >= deposit.unlockTime, "The amount is locked and cannot be withdrawn yet");

        IERC20 token = IERC20(deposit.tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));

        require(contractBalance >= deposit.amount, "Insufficient contract balance");

        token.transfer(msg.sender, deposit.amount);

        delete deposits[msg.sender][_depositId];

        emit Withdrawn(msg.sender, _depositId, msg.sender, deposit.amount);
    }

    function getWithdrawSchedules(address _user) external view returns (WithdrawSchedule[] memory) {
        uint256 count;

        // Count the number of relevant deposits for the user
        for (uint256 i = 0; i < depositCounters[_user]; i++) {
            if (deposits[_user][i].depositor == _user || deposits[_user][i].withdrawer == _user) {
                count++;
            }
        }

        WithdrawSchedule[] memory schedules = new WithdrawSchedule[](count);

        // Populate the array with depositIds, unlockTimes, and amounts
        uint256 index;
        for (uint256 i = 0; i < depositCounters[_user]; i++) {
            if (deposits[_user][i].depositor == _user || deposits[_user][i].withdrawer == _user) {
                schedules[index] = WithdrawSchedule(i, deposits[_user][i].unlockTime, deposits[_user][i].amount);
                index++;
            }
        }

        return schedules;
    }
}