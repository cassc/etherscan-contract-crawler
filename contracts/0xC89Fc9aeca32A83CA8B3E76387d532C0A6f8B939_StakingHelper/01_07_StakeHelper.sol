//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingHelper is Ownable, ERC20("EDGR Staking", "xEDGR" ) {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    uint256 public rewardRate = 200000000000000000;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 public _totalSupply;
    mapping(address => uint256) public _balances;
    
    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    function setRewardRate(uint256 _newRate) external onlyOwner {
        rewardRate = _newRate;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return
            ((super.balanceOf(account) *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    function stake(uint256 _amount) external updateReward(msg.sender) {
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require(_amount <= super.balanceOf(msg.sender));
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
        _burn(msg.sender, _amount);
    }

    function getReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);
    }

    function compound() external updateReward(msg.sender) {
        uint256 compoundAmount = rewards[msg.sender];
        rewards[msg.sender] = 0;
        _mint(msg.sender, compoundAmount);
    }

    function getUserXedgrBal(address account) public view returns(uint256){
        return super.balanceOf(account);
    }

    function emergencyRescueToken(address token) public onlyOwner{
        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }
}