// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./Interfaces/IStakingRewards.sol";

/**
@title RewardsDistributionRecipient
@notice
 */
abstract contract RewardsDistributionRecipient {
    address public rewardsDistribution; //factory contract address

    function notifyRewardAmount(uint256 rewardAmount1, uint256 rewardAmount2, uint256 duration) external virtual;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }
}
/**
@title StakingRewards
@notice controls a pool
@dev it is created automatically when you call deploy function at factory contract
 */
contract StakingRewards is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    address public xcbContract;
    address public btcbContract;
    address public stakingTokenContract;
    IERC20 public rewardsToken1; 
    IERC20 public rewardsToken2;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardRate2 = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored1;
    uint256 public rewardPerTokenStored2;
    uint256 public depositFee;
    uint256 public poolMaxCap;
    uint256 public userMaxCap;
    address public feeRecipient;
    uint256 public nftId;

    mapping(address => uint256) public userRewardPerTokenPaid1;
    mapping(address => uint256) public userRewardPerTokenPaid2;
    mapping(address => uint256) public rewards1;
    mapping(address => uint256) public rewards2;

    uint256 private _totalSupply;

    //balances of staked token
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */


    constructor(
        address _rewardsDistribution,
        uint256 _depositFee,
        uint256 _poolMaxCap,
        uint256 _userMaxCap,
        address _feeRecipient,
        address _xcbContract,
        address _btcbContract,
        address _stakingTokenContract
    ) {
        rewardsDistribution = _rewardsDistribution;
        depositFee = _depositFee;
        poolMaxCap = _poolMaxCap;
        userMaxCap = _userMaxCap;
        feeRecipient = _feeRecipient;
        xcbContract = _xcbContract;
        btcbContract = _btcbContract;
        stakingTokenContract = _stakingTokenContract;
        rewardsToken1 = IERC20(xcbContract);
        rewardsToken2 = IERC20(btcbContract);
        stakingToken = IERC20(stakingTokenContract);
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view override returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken1() public view override returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored1;
        }
        return
            rewardPerTokenStored1.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            ); ///@dev rewardPerTokenStored + (((MaxTimeToGetRward - LastUpdateTime)*RewardRate*1e18)/totaSuply)
    }
    function rewardPerToken2() public view override returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored2;
        }
        return
            rewardPerTokenStored2.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate2).mul(1e18).div(_totalSupply)
            ); ///@dev rewardPerTokenStored + (((MaxTimeToGetRward - LastUpdateTime)*RewardRate*1e18)/totaSuply)
    }

    function earned(address account) public view override returns (uint256) {
        return _balances[account].mul(rewardPerToken1().sub(userRewardPerTokenPaid1[account])).div(1e18).add(rewards1[account]);
        ///@dev Rewards + balance * ((RewardPerTokenStored - RewardPerTokenStoredPaid)/1e18)
    }
    function earned2(address account) public view override returns (uint256) {
        return _balances[account].mul(rewardPerToken2().sub(userRewardPerTokenPaid2[account])).div(1e18).add(rewards2[account]);
        ///@dev Rewards + balance * ((RewardPerTokenStored - RewardPerTokenStoredPaid)/1e18)
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external override nonReentrant updateRewards(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        uint fee = amount.mul(depositFee).div(100);
        if(userMaxCap > 0){
            require(_balances[msg.sender].add(amount).sub(fee) <= userMaxCap, "User max cap reached");
        }
        if(poolMaxCap > 0){
            require(_totalSupply <= poolMaxCap, "Pool max cap reached");
        }
        _totalSupply = _totalSupply.add(amount).sub(fee);
        _balances[msg.sender] = _balances[msg.sender].add(amount).sub(fee);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount.sub(fee));
        if(fee > 0){
            stakingToken.safeTransferFrom(msg.sender, feeRecipient, fee);
        }
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override nonReentrant updateRewards(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getRewards() external override nonReentrant {
        getReward1();
        getReward2();
        emit RewardsPaid(msg.sender);
    }

    function getReward1() internal updateRewards(msg.sender) {
        uint256 reward1 = rewards1[msg.sender];
        if (reward1 > 0) {
            rewards1[msg.sender] = 0;
            rewardsToken1.safeTransfer(msg.sender, reward1);
            emit RewardPaid1(msg.sender, reward1);
        }
    }

    function getReward2() internal updateRewards(msg.sender) {
        uint256 reward2 = rewards2[msg.sender];
        if (reward2 > 0) {
            rewards2[msg.sender] = 0;
            rewardsToken2.safeTransfer(msg.sender, reward2);
            emit RewardPaid2(msg.sender, reward2);
        }
    }

    function exit() external override {
        withdraw(_balances[msg.sender]);
            getReward1();
            getReward2();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward1, uint256 reward2, uint256 rewardsDuration) external override onlyRewardsDistribution updateRewards(address(0)) {
        require(block.timestamp.add(rewardsDuration) >= periodFinish, "Cannot reduce existing period");
    
        if (block.timestamp >= periodFinish) {
            rewardRate = reward1.div(rewardsDuration);
            rewardRate2 = reward2.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover1 = remaining.mul(rewardRate);
            uint256 leftover2 = remaining.mul(rewardRate2);
            rewardRate = reward1.add(leftover1).div(rewardsDuration);
            rewardRate2 = reward2.add(leftover2).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance1 = rewardsToken1.balanceOf(address(this));
        uint balance2 = rewardsToken2.balanceOf(address(this));
        require(rewardRate <= balance1.div(rewardsDuration), "Provided reward too high");
        require(rewardRate2 <= balance2.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded1(reward1, periodFinish);
        emit RewardAdded2(reward2, periodFinish);
    }

    function updateFee( uint256 _depositFee) external onlyRewardsDistribution {
        depositFee = _depositFee;
    }

    function updatePoolMaxCap(uint256 _poolMaxCap) external onlyRewardsDistribution {
        poolMaxCap = _poolMaxCap;
    }

    function updateUserMaxCap(uint256 _userMaxCap) external onlyRewardsDistribution {
        userMaxCap = _userMaxCap;
    }

    function updateRecipient(address _feeRecipient) external onlyRewardsDistribution {
        feeRecipient = _feeRecipient;
    }

    /* ========== MODIFIERS ========== */

    modifier updateRewards(address account) {
        rewardPerTokenStored1 = rewardPerToken1();
        rewardPerTokenStored2 = rewardPerToken2();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards1[account] = earned(account);
            rewards2[account] = earned2(account);
            userRewardPerTokenPaid1[account] = rewardPerTokenStored1;
            userRewardPerTokenPaid2[account] = rewardPerTokenStored2;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded1(uint256 reward1, uint256 periodFinish);
    event RewardAdded2(uint256 reward2, uint256 periodFinish);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardsPaid(address indexed user);
    event RewardPaid1(address indexed user, uint256 reward1);
    event RewardPaid2(address indexed user, uint256 reward2);
}