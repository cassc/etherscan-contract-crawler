//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract StakingRewards is AccessControl{
    using SafeMath for uint256;

    bytes32 public constant GAMER_ROLE = keccak256("GAMER_ROLE");

    IGOLDTOKEN public rewardsToken;
    IERC20 public stakingToken;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Rewarded(address indexed user, uint256 amount);

    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    uint256 public apy = 10000;  // 100%
    uint256 constant public secondsPerYear = 31536000;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(address _stakingToken, address _rewardsToken) {
        _setupRole(DEFAULT_ADMIN_ROLE,msg.sender);
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IGOLDTOKEN(_rewardsToken);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
    
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add((block.timestamp.sub(lastUpdateTime)).mul(1e18).mul(apy).div(secondsPerYear).div(10000));
    }

    function setAPY(uint256 _apy) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        apy = _apy;
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    function gameStake(address account, uint256 _amount) public onlyRole(GAMER_ROLE) updateReward(account){
        _stake(account, _amount);
    }

    function stake(uint256 _amount) public {
        _stake(msg.sender, _amount);
    }

    function _stake(address _account, uint256 _amount) private updateReward(_account) {
        require(_amount > 0,"Can't stake 0 or less");
        _totalSupply = _totalSupply.add(_amount);
        _balances[_account] = _balances[_account].add(_amount);
        stakingToken.transferFrom(_account, address(this), _amount);
        emit Staked(_account, _amount);
    }

    function gameWithdraw(address _account, uint256 _amount) public onlyRole(GAMER_ROLE) updateReward(_account){
        _withdraw(_account, _amount);
    }

    function withdraw(uint256 _amount) public {
        _withdraw(msg.sender, _amount);
    }

    function _withdraw(address _account, uint256 _amount) private updateReward(_account) {
        require(_amount > 0,"Can't withdraw 0 or less");
        _totalSupply = _totalSupply.sub(_amount);
        _balances[_account] = _balances[_account].sub(_amount);
        stakingToken.transfer(_account, _amount);
        emit Withdrawn(_account, _amount);
    }

    function gameGetReward(address _account) public onlyRole(GAMER_ROLE) updateReward(_account){
        _getReward(_account);
    }

    function getReward() public {
        _getReward(msg.sender);
    }

    function _getReward(address _account) private updateReward(_account) {
        uint256 reward = rewards[_account];
        rewards[_account] = 0;
        rewardsToken.rewardMint(_account, reward);
        emit Rewarded(_account, reward);
    }

    function gameExit(address _account) external {
        gameWithdraw(_account, _balances[_account]);
        gameGetReward(_account);
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function rewardMint(address account, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IGOLDTOKEN is IERC20{
    function rewardMint(address account, uint256 amount) override external returns (bool);
}