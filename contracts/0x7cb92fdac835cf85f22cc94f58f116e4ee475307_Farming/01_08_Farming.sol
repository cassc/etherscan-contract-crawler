// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "ERC20.sol";
import "SafeERC20.sol";

contract TestCoin is ERC20 {
    constructor(address _to, uint256 _initialSupply) ERC20("TestToken", "TT") {
        _mint(_to, _initialSupply);
    }
}

contract Farming is ERC20 {
    using SafeERC20 for IERC20;

    IERC20 public depositedToken;
    mapping(address => uint256) public depositedInfo;
    mapping(address => uint256) public rewardDebt;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(IERC20 _depositedToken) ERC20("Rewards", "CR") {
        depositedToken = _depositedToken;
    }

    function getReward(address _addr) public view returns (uint) {
        return rewardDebt[_addr];
    }

    function deposit(uint256 _amount) external {
        require(_amount > 0, "Illegal amount");
        depositedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        depositedInfo[msg.sender] += _amount;
        rewardDebt[msg.sender] += _amount / 100;
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        require(depositedInfo[msg.sender] > 0, "No deposit");
        require(depositedInfo[msg.sender] >= _amount, "Illegal amount");
        if (_amount == 0) {
            _amount = depositedInfo[msg.sender];
        }
        depositedToken.safeTransfer(address(msg.sender), _amount);
        depositedInfo[msg.sender] = depositedInfo[msg.sender] - _amount;
        emit Withdraw(msg.sender, _amount);
    }

    function claim(address addr) external {
        uint rewardAmount = getReward(addr);
        require(rewardAmount > 0, "Out of rewards");
        rewardDebt[addr] = 0;
        _mint(addr, rewardAmount);
    }
}