// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Staking is ReentrancyGuard 
{    
    IERC20 public token;

    struct UserInfo {
        uint256 amount;
        uint256 since;
        uint256 rewardDebt;
    }

    address owner;
    address factoryContract;
                                 
    uint256 public rewards;
    uint256 public decimals;
    uint256 public _totalSupply;
    uint256 public rewardsDuration;
    
    bool pause;

    mapping(address => UserInfo) userInfo;

    event Staked(address user, uint256 amount);
    event Withdrawn(address user, uint256 amount);
    event RewardPaid(address user, uint256 reward);

    modifier updateReward(address account) {
        userInfo[msg.sender].rewardDebt = earned(msg.sender);
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not a owner");
        _;
    }

    modifier paused() {
        require(!pause, "contract is paused");
        _;
    }

    constructor(
        address _token,
        address _owner,
        address _factoryContract,
        uint256 _rewards,
        uint256 _decimals,
        uint256 _rewardsDuration
    ) {
        owner = _owner;
        token = IERC20(_token);
        factoryContract = _factoryContract;
        rewards = _rewards;
        decimals = _decimals;
        rewardsDuration = _rewardsDuration;
    }

    function stake(uint256 _amount)
        external
        nonReentrant
        paused
        updateReward(msg.sender)
    {
        _totalSupply += _amount;
        userInfo[msg.sender].amount += _amount;
        userInfo[msg.sender].since = block.timestamp;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount)
        public
        nonReentrant
        paused
        updateReward(msg.sender)
    {
        require(userInfo[msg.sender].amount>0,"token not stake");
        require((block.timestamp-userInfo[msg.sender].since)>=rewardsDuration,"not lockingtime");
        _totalSupply = _totalSupply -  _amount;
        userInfo[msg.sender].amount = userInfo[msg.sender].amount -  _amount;
        userInfo[msg.sender].since = block.timestamp;
        token.transfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }
    
    function getReward(address _user) public nonReentrant paused returns(uint256) 
    {
        require(userInfo[_user].amount>0,"token not stake");
        require(factoryContract == msg.sender,"not factory contract");
        require((block.timestamp-userInfo[_user].since)>=rewardsDuration,"not claim time");
        uint256 reward = earned(_user);
        userInfo[_user].rewardDebt = 0;
        userInfo[_user].since = block.timestamp;
        
        emit RewardPaid(_user, reward);
        return reward;
    }

    function pausedContract(bool _status) external nonReentrant onlyOwner {
        pause = _status;
    }
    
    function earned(address _account) public view returns (uint256) {
        return
            userInfo[msg.sender].rewardDebt +
            (((block.timestamp - userInfo[_account].since)* userInfo[_account].amount * rewards)  /
                (rewardsDuration*decimals));
    }

    function stakeBalanceOfUser(address _user) external view returns (uint256) {
        return userInfo[_user].amount;
    }

    function getUserDetails(address _user) external view returns(UserInfo memory)
    {
        return userInfo[_user];
    }
}