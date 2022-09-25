// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IFarm.sol";

contract DEFIWZFarm is Ownable, ReentrancyGuard,IFarm {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant REWARDS_DAYS = 30 days;

    IERC20 public immutable defiWz;
    IERC20 public immutable wzDao;
    address public immutable defiWzWhitelist;
    uint256 public minStakingTokenAAmount;
    
    uint256 public periodFinish = 0;
    uint256 public avgRewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public totalSupply;

    mapping(address => uint256) private _userRewardPerTokenPaids;
    mapping(address => uint256) private _rewards;
    mapping(address => uint256) private _balances;

    constructor(IERC20 wzDao_,IERC20 defiWz_,address defiWzWhitelist_,uint256 minStakingTokenAAmount_) {
        defiWz = defiWz_;
        wzDao = wzDao_;
        defiWzWhitelist = defiWzWhitelist_;
        minStakingTokenAAmount = minStakingTokenAAmount_;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
                (((lastTimeRewardApplicable() - lastUpdateTime) * getRewardRate() * 1e18) / totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return
            ((_balances[account] *
                (rewardPerToken() - _userRewardPerTokenPaids[account])) / 1e18) +
                    _rewards[account];
    }

    function getHash(address _address) public view returns (uint256) {
        return _balances[_address];
    }

    function getRewardRate()public view returns(uint256){
        return avgRewardRate.mul(totalSupply).div(1e18);
    }

    function stake(uint256 _amount) external updateReward(msg.sender) nonReentrant
    {
        require(_amount>0,"The amount must be greater than 0");
        address user = msg.sender;
        require(getHash(user).add(_amount) >= minStakingTokenAAmount,"The staking amount must be greater than minStakingTokenAAmount");
        require(defiWz.balanceOf(user) >= _amount,"Insufficient balance");
        defiWz.safeTransferFrom(user, defiWzWhitelist, _amount);
        _stake(user, _amount);
        emit Stake(user, _amount);
    }

    function withdraw() external updateReward(msg.sender) nonReentrant
    {
        address user = msg.sender;
        uint256 amount = getHash(user);
        defiWz.safeTransferFrom(defiWzWhitelist, user, amount);
        _withdraw(user, amount);
        emit Withdraw(user, amount);
    }

    function getReward(address _user) external updateReward(_user) {
        uint256 reward = _rewards[_user];
        if (reward > 0) {
            _rewards[_user] = 0;
            wzDao.safeTransfer(_user, reward);
            emit RewardPaid(_user, reward);
        }
    }

    function _stake(address _address, uint256 _amount) private {
        totalSupply += _amount;
        _balances[_address] += _amount;
    }

    function _withdraw(address _address, uint256 _amount) private {
        totalSupply -= _amount;
        _balances[_address] -= _amount;
    }

    function setAvgRewardRate(uint256 _avgRewardRate)
        external
        onlyOwner
        updateReward(address(0))
    {
        avgRewardRate = _avgRewardRate;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + REWARDS_DAYS;
    }

    function setMinStakingTokenAAmount(uint256 _minStakingTokenAAmount) external onlyOwner{
        minStakingTokenAAmount = _minStakingTokenAAmount;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            _rewards[account] = earned(account);
            _userRewardPerTokenPaids[account] = rewardPerTokenStored;
        }
        _;
    }

    event Stake(address user, uint256 amount);
    event Withdraw(address user,uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}