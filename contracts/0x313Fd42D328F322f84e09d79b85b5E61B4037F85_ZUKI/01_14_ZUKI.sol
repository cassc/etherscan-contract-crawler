//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract ZUKI is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{

    string public constant name = "ZUKI";
     using SafeERC20Upgradeable for IERC20Upgradeable;

    //  total amount staked on pool
    mapping(uint256 => uint256) public totalStakedAmountInPool;
    // balance stakable on pool
    mapping(uint256 => uint256) private balanceStakableAmount;
    mapping(address => bool) public blacklisted;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 stakingStartTime; // Staking start time in pool
        uint256 stakingEndTime; // Staking End time in pool
        bool hasStaked; // check is account staked
        bool isStaking; // check is account currently staking
        uint256 depositReward; // Reward for deposit
        uint256 interestReward; // Interest for staking period
        uint256 expectedReward; // expected reward of staking
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20Upgradeable lpToken; // Address of LP token contract.
        IERC20Upgradeable rewardToken; // Address of Reward token contract
        uint256 startTime; // Lp's start time
        uint256 endTime; // Lp's end time
        uint256 rewardRate; // reward rate in percentage (APR)
        uint256 duration; // duration of each user staking time to collect reward
        uint256 depositRewardRate; // user will get deposit-reward (stake amount * % / 100)
        uint256 poolStakableAmount; // pools total stakable amount
    }

    event Reward(address indexed from, address indexed to, uint256 amount);
    event StakedToken(address indexed from, address indexed to, uint256 amount);
    event UpdatedStakingEndTime(uint256 endTime);
    event WithdrawAll(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event AccountblacklistUpdated(address indexed account, bool status);
    event AccountsblacklistUpdated(address[] indexed accounts, bool status);
  /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        // initializing
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
   
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
       @dev get pool length
       @return current pool length
    */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
       @dev get current block timestamp
       @return current block timestamp
    */
    function getCurrentBlockTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    /**
       @dev setting staking pool end time
       @param _pid index of the array i.e pool id
       @param _endTime when staking pool ends
    */
    function setPoolStakingEndTime(uint256 _pid, uint256 _endTime)
        external
        virtual
        onlyOwner
        whenNotPaused
    {
        require( poolInfo[_pid].endTime > poolInfo[_pid].startTime,"end time must be greater than start time");
        poolInfo[_pid].endTime = _endTime;
        emit UpdatedStakingEndTime(_endTime);
    }

    /** 
       @dev returns the total staked tokens in pool and it is independent of the total tokens in pool keeps
       @param _pid index of the array i.e pool id
       @return total staked amount in pool
    */
    function getTotalStakedInPool(uint256 _pid)
        external
        view
        returns (uint256)
    {
        return totalStakedAmountInPool[_pid];
    }

    /** 
       @dev returns the total staked user tokens in pool and it is independent of the total tokens in pool keeps
       @param _pid index of the array i.e pool id
       @return user staked balance in particular pool
    */
    function getUserStakedTokenInPool(uint256 _pid)
        external
        view
        returns (uint256)
    {
        return userInfo[_pid][msg.sender].amount;
    }

    /**
       @dev Add a new lp to the pool. Can only be called by the owner.
       @param _lpToken user staking token
       @param _rewardToken user rewarded token
       @param _startTime when pool starts
       @param _endTime when pool ends
       @param _rewardRate (APR) in %
    */
    function addPool(
        IERC20Upgradeable _lpToken,
        IERC20Upgradeable _rewardToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rewardRate,
        uint256 _duration,
        uint256 _depositReward,
        uint256 _poolStakableAmount
    ) public onlyOwner {
        _beforeAddPool(_startTime, _endTime, _rewardRate);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                rewardToken: _rewardToken,
                startTime: _startTime,
                endTime: _endTime,
                rewardRate: _rewardRate,
                duration: _duration,
                depositRewardRate: _depositReward,
                poolStakableAmount:_poolStakableAmount
            })
            
        );
        
    }

    /**
       @dev AddPool validations.
       @param _startTime when pool starts
       @param _endTime when pool ends
       @param _rewardRate (APR) in %
    */
    function _beforeAddPool(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rewardRate
    ) internal virtual {
        require(
            block.timestamp >= _startTime,
            "STAKING: Start Block has not reached"
        );
        require(block.timestamp <= _endTime, "STACKING: Has Ended");
        require(
            _rewardRate > 0,
            "Reward Rate(APR) in %: Must be greater than 0"
        );
    }

    /**
       @dev Stake LP token's.
       @param _pid index of the array i.e pool id
       @param _amount staking amount
    */
    function stakeTokens(uint256 _pid, uint256 _amount)
        external
        virtual
        whenNotPaused
    {
        _beforeStakeTokens(_pid, _amount);
        require(!blacklisted[msg.sender], "Swap: Account is blacklisted");
        UserInfo storage user = userInfo[_pid][msg.sender];
        bool transferStatus = poolInfo[_pid].lpToken.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        if (transferStatus) {
            // update user staking balance in particular pool
            user.amount = user.amount + _amount;
            // update Contract Staking balance in pool
            balanceStakableAmount[_pid] = poolInfo[_pid].poolStakableAmount - totalStakedAmountInPool[_pid];
            require(block.timestamp < poolInfo[_pid].endTime,"Staking ended");
            require((totalStakedAmountInPool[_pid] + _amount) <= poolInfo[_pid].poolStakableAmount,"Total Amount must be less than stakable amount");
            // save the time when they started staking in particular pool
            user.stakingStartTime = block.timestamp;
            totalStakedAmountInPool[_pid] += _amount;
            //staking end time of particular user in particular pool
            user.stakingEndTime =
                block.timestamp +
                (poolInfo[_pid].duration * 1 minutes);
            //expected reward after staking period
            user.expectedReward +=
                ((_amount * poolInfo[_pid].rewardRate) / 100) +
                ((_amount * poolInfo[_pid].depositRewardRate) / 100);
            //interest reward
            user.interestReward += ((_amount * poolInfo[_pid].rewardRate) /
                100);
            //deposit reward
            user.depositReward += ((_amount *
                poolInfo[_pid].depositRewardRate) / 100);
            // update staking status in particular pool
            user.hasStaked = true;
            user.isStaking = true;
            emit StakedToken(msg.sender, address(this), _amount);
        }
    }

    function _beforeStakeTokens(uint256 _pid, uint256 _amount)
        internal
        virtual
    {
        require(_amount > 0, "STAKING: Amount cannot be 0");
        require(_pid <= poolInfo.length, "Withdraw: Pool not exist");
        require(
            poolInfo[_pid].lpToken.balanceOf(msg.sender) >= _amount,
            "STAKING: Insufficient stake token balance"
        );
    }

    /**
       @dev check if the reward token is same as the staking token
         If staking token and reward token is same then -
         Contract should always contain more or equal tokens than staked tokens
         Because staked tokens are the locked amount that staker can unstake any time 
       @param _pid index of the array i.e pool id
       @param calculatedReward reward send to caller
       @param _toAddress caller address got reward
    */
    function SendRewardTo(
        uint256 _pid,
        uint256 calculatedReward,
        address _toAddress
    ) internal virtual returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];
        require(_toAddress != address(0), "STAKING: Address cannot be zero");
        require(
            pool.rewardToken.balanceOf(address(this)) >= calculatedReward,
            "STAKING: Not enough reward balance"
        );

        if (pool.lpToken == pool.rewardToken) {
            if (
                (pool.rewardToken.balanceOf(address(this)) - calculatedReward) <
                totalStakedAmountInPool[_pid]
            ) {
                calculatedReward = 0;
            }
        }
        bool successStatus = false;
        if (calculatedReward > 0) {
            bool transferStatus = pool.rewardToken.transfer(
                _toAddress,
                calculatedReward
            );
            require(transferStatus, "STAKING: Transfer Failed");
            if (userInfo[_pid][_toAddress].amount == 0) {
                userInfo[_pid][_toAddress].isStaking = false;
            }
            // oldReward[_toAddress] = 0;
            emit Reward(address(this), _toAddress, calculatedReward);
            successStatus = true;
        }
        return successStatus;
    }

    /**
       @dev  withdraw all staked tokens and reward tokens
       @param _pid index of the array i.e pool id
     */
    function withdrawAll(uint256 _pid) external {
        require(_pid <= poolInfo.length, "Withdraw: Pool not exist");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "Withdraw: Not enough reward balance");
        require(
            block.timestamp > user.stakingEndTime,
            "Staking period not yet completed"
        );
        uint256 reward = user.expectedReward;
        if (reward > 0) {
            uint256 rewardTokens = poolInfo[_pid].rewardToken.balanceOf(
                address(this)
            );
            require(
                rewardTokens > reward,
                "STAKING: Not Enough Reward Balance"
            );
            bool rewardSuccessStatus = SendRewardTo(_pid, reward, msg.sender);
            require(rewardSuccessStatus, "Withdraw: Claim Reward Failed");
        }
        user.expectedReward -= reward;
        user.interestReward = 0;
        user.depositReward = 0;
        uint256 amount = user.amount;
        user.amount = 0;
        user.isStaking = false;
        pool.lpToken.transfer(address(msg.sender), amount);
        emit WithdrawAll(msg.sender, _pid, amount);
    }
  

    /**
    @dev Include specific address for blacklisting
    @param account - blacklisting address
    */
    function includeInblacklist(address account) external onlyOwner {
        require(account != address(0), "Swap: Account cant be zero address");
        require(!blacklisted[account], "Swap: Account is already blacklisted");
        blacklisted[account] = true;
        emit AccountblacklistUpdated(account, true);
    }

    /**
    @dev Exclude specific address from blacklisting
    @param account - blacklisting address
    */
    function excludeFromblacklist(address account) external onlyOwner {
        require(account != address(0), "Swap: Account cant be zero address");
        require(blacklisted[account], "Swap: Account is not blacklisted");
        blacklisted[account] = false;
        emit AccountblacklistUpdated(account, false);
    }

    /**
    @param _pid index of the pool
     */
    function balanceStakableToken(uint256 _pid)public view returns(uint256){
       return (poolInfo[_pid].poolStakableAmount - totalStakedAmountInPool[_pid]);
       
    }
    
    /** 
    @dev Pause contract by owner
    */
    function pauseContract() external virtual onlyOwner {
        _pause();
    }

    /**
    @dev Unpause contract by owner
    */
    function unPauseContract() external virtual onlyOwner {
        _unpause();
    }

}