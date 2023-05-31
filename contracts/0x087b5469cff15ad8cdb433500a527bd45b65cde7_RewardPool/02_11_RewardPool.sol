// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./KeyfiToken.sol";
import "./Whitelist.sol";

 /**
 * @title RewardPool
 * @dev Implementation of Reward logic for KEYFI token, based on SushiSwap's MasterChef.
 */
contract RewardPool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for KeyfiToken;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of reward
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each staking token
    struct StakingToken {
        IERC20 stakingToken;            // Contract address of token to be staked
        uint256 allocPoint;             // How many allocation points assigned to this token
        uint256 lastRewardBlock;        // Last block number that reward distribution occurred
        uint256 accRewardPerShare;      // Accumulated reward per share, times 1e12.
    }

    struct TokenIndex {
        uint256 index;
        bool added;
    }

    KeyfiToken public immutable rewardToken;
    uint256 public immutable bonusEndBlock;                   // Block number when bonus reward period ends
    uint256 public immutable bonusMultiplier;  // Bonus muliplier for early users
    uint256 public rewardPerBlock;                  // reward tokens distributed per block
    Whitelist public whitelist;

    StakingToken[] public stakingTokens;                                    // Info of each pool
    mapping(address => TokenIndex) public stakingTokenIndexes;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;     // Info of each user that stakes tokens
    uint256 public totalAllocPoint = 0;                                     // Total allocation points. Must be the sum of all allocation points in all pools
    uint256 public startBlock;                                              // The block number when rewards start
    uint256 public launchDate;

    event TokenAdded(address indexed token, uint256 allocPoints);
    event TokenRemoved(address indexed token);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawRewards(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPerBlockChanged(uint256 previousRate, uint256 newRate);
    event SetAllocPoint(address token, uint256 allocPoints);

    constructor(
        KeyfiToken _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _bonusMultiplier,
        Whitelist _whitelist,
        uint256 _launchDate
    ) 
    {
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        bonusMultiplier = _bonusMultiplier;
        whitelist = _whitelist;
        launchDate = _launchDate;
    }

    function stakingTokensCount() 
        external 
        view 
        returns (uint256) 
    {
        return stakingTokens.length;
    }

    /**
     * @dev adds a token to the list of allowed staking tokens
     * @param _allocPoint — The "weight" of this token in relation to other allowed tokens.
     * @param _stakingToken — The token to be added.
     */
    function addStakingToken(uint256 _allocPoint, IERC20 _stakingToken) 
        public 
        onlyOwner 
    {
        // since owner is able to arbitrarily withdraw reward tokens from the contract
        // it doesn't allow using the same reward token as a staking token
        require(address(_stakingToken) != address(rewardToken), "cannot add reward token as staking token");
        require(!stakingTokenIndexes[address(_stakingToken)].added, "staking token already exists in array");

        massUpdateTokens();
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        stakingTokens.push(StakingToken({
            stakingToken: _stakingToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accRewardPerShare: 0
        }));

        stakingTokenIndexes[address(_stakingToken)] = TokenIndex({
            index: stakingTokens.length - 1,
            added: true
        });

        emit TokenAdded(address(_stakingToken), _allocPoint);
    }

    // CHECK STAKING TOKEN ADDED
    function isStakingToken(IERC20 _token) 
        external 
        view 
        returns (bool) 
    {
        return stakingTokenIndexes[address(_token)].added;
    }

    /**
     * @dev changes the weight allocation for a particular token
     * @param _token — The token to be configured.
     * @param _allocPoint — The allocation points set to this token
     */
    function setAllocPoint(IERC20 _token, uint256 _allocPoint) 
        public 
        onlyOwner 
    {
        require(stakingTokenIndexes[address(_token)].added, "token does not exist in list");
        //require(_allocPoint > 0, "allocation points must be greater than zero");

        massUpdateTokens();
        uint256 index = stakingTokenIndexes[address(_token)].index;
        totalAllocPoint = totalAllocPoint.sub(stakingTokens[index].allocPoint).add(_allocPoint);
        stakingTokens[index].allocPoint = _allocPoint;
        emit SetAllocPoint(address(_token), _allocPoint);
    }

    function setRewardPerBlock(uint256 _newRate)
        external
        onlyOwner
    {
        massUpdateTokens();
        emit RewardPerBlockChanged(rewardPerBlock, _newRate);
        rewardPerBlock = _newRate;
    }

    /**
     * @dev gets multiplier factor for possible bonuses within any given period
     * @param _from — starting block
     * @param _to — last block of the period
     */
    function getMultiplier(uint256 _from, uint256 _to) 
        public 
        view 
        returns (uint256) 
    {
        _from = _from >= startBlock? _from : startBlock;
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(bonusMultiplier);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(bonusMultiplier).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

    /**
     * @dev calculates pending reward for a given staking token and a user
     * @param _token — The staking token
     * @param _user — The stakeholder 
     */
    function pendingReward(IERC20 _token, address _user) 
        external 
        view 
        returns (uint256) 
    {
        require(stakingTokenIndexes[address(_token)].added, "invalid token");

        uint256 _pid = stakingTokenIndexes[address(_token)].index;
        StakingToken storage pool = stakingTokens[_pid];

        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 tokenSupply = pool.stakingToken.balanceOf(address(this));   // <----- counting actual deposits. Anyone can send tokens and dilute everyone's share
        
        if (block.number > pool.lastRewardBlock && tokenSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 reward = (pool.allocPoint == 0)? 0 : multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(tokenSupply));
        }

        return user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }

    /**
     * @dev invokes a checkpoint update on all staking tokens in the list
     */
    function massUpdateTokens() 
        public 
    {
        uint256 length = stakingTokens.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            checkpoint(pid);
        }
    }

    /**
     * @dev Calculates all reward rates for all staking tokens since last checkpoint. 
     * Should be called before any balance-changing operations (e.g. deposit, withdraw)
     * @param _pid — The index of the token in the array of staking tokens
     */
    function checkpoint(uint256 _pid) 
        public 
    {
        require(_pid < stakingTokens.length, "token index out of bounds");

        StakingToken storage pool = stakingTokens[_pid];
        
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 stakedSupply = pool.stakingToken.balanceOf(address(this));

        if (stakedSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 reward = (pool.allocPoint == 0)? 0 : multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        
        //rewardToken.mint(address(this), reward);

        pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e12).div(stakedSupply));
        pool.lastRewardBlock = block.number;
    }

    // GET STAKED TOKEN BALNCE
    function getBalance(IERC20 _token) 
        external 
        view 
        returns (uint256)
    {
        require(stakingTokenIndexes[address(_token)].added, "invalid token");
        uint256 _pid = stakingTokenIndexes[address(_token)].index;
        UserInfo storage user = userInfo[_pid][msg.sender];

        return user.amount;
    }

    /**
     * @dev deposit _amount into a given _token pool
     * @param _token — The staking token to be deposited
     * @param _amount — The amount of tokens to be staked
     */
    function deposit(IERC20 _token, uint256 _amount) 
        public 
    {
        require(stakingTokenIndexes[address(_token)].added, "invalid token");
        require(whitelist.isWhitelisted(msg.sender), "sender address is not eligible");
        require(block.timestamp >= launchDate, "deposits are not enabled yet");
        
        uint256 _pid = stakingTokenIndexes[address(_token)].index;
        checkpoint(_pid);
        StakingToken storage pool = stakingTokens[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        user.amount = user.amount.add(_amount);

        uint256 rewardBal = rewardToken.balanceOf(address(this));
        uint256 diff = 0;

        if (rewardBal < pending) {
            diff = pending.sub(rewardBal);
        }

        user.rewardDebt = (user.amount.mul(pool.accRewardPerShare).div(1e12)).sub(diff);
        
        safeRewardTransfer(msg.sender, pending);
        if (_amount > 0) {
            pool.stakingToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            emit Deposit(msg.sender, _pid, _amount);
        }
    }

    /**
     * @dev withdraw _amount of a given staking token
     * @param _token — The staking token to be withdrawn
     * @param _amount — The amount of tokens to withdraw
     */
    function withdraw(IERC20 _token, uint256 _amount) 
        public 
    {
        require(stakingTokenIndexes[address(_token)].added, "invalid token");
        
        uint256 _pid = stakingTokenIndexes[address(_token)].index;
        StakingToken storage pool = stakingTokens[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "invalid amount specified");

        checkpoint(_pid);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        user.amount = user.amount.sub(_amount);

        uint256 rewardBal = rewardToken.balanceOf(address(this));
        uint256 diff = 0;
        
        if (rewardBal < pending) {
            diff = pending.sub(rewardBal);
        }

        user.rewardDebt = (user.amount.mul(pool.accRewardPerShare).div(1e12)).sub(diff);

        if(whitelist.isWhitelisted(msg.sender)) {
            safeRewardTransfer(msg.sender, pending);
        }
        
        if(_amount > 0) {
            pool.stakingToken.safeTransfer(address(msg.sender), _amount);
            emit Withdraw(msg.sender, _pid, _amount);
        }
    }

    // WITHDRAW TOKENS ONLY
    function withdrawRewards(IERC20 _token)
        public
    {
        require(stakingTokenIndexes[address(_token)].added, "invalid token");
        
        uint256 _pid = stakingTokenIndexes[address(_token)].index;
        StakingToken storage pool = stakingTokens[_pid];

        UserInfo storage user = userInfo[_pid][msg.sender];

        checkpoint(_pid);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        uint256 diff = 0;
        
        if (rewardBal < pending) {
            diff = pending.sub(rewardBal);
        }

        user.rewardDebt = (user.amount.mul(pool.accRewardPerShare).div(1e12)).sub(diff);

        if(whitelist.isWhitelisted(msg.sender)) {
            safeRewardTransfer(msg.sender, pending);
            emit WithdrawRewards(msg.sender, pending);
        }
    }

    /**
     * @dev withdraw all staked funds of a given token, regardless of reward logic
     * To be used in an emergency case if reward logic fails and tokens would get locked otherwise
     * @param _token — The staking token to withdraw funds from
     */
    function emergencyWithdraw(IERC20 _token) 
        public 
    {
        require(stakingTokenIndexes[address(_token)].added, "invalid token");
        
        uint256 _pid = stakingTokenIndexes[address(_token)].index;
        StakingToken storage pool = stakingTokens[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        pool.stakingToken.safeTransfer(address(msg.sender), _amount);
        
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    /**
     * @dev Internal function to send rewards while checking for potential imbalances
     * Note: if available reward is less than calculated amount, reward will still take place
     * And pending reward calculations might 
     * @param _to — the target address of the reward
     * @param _amount — the amount of reward to transfer
     */
    function safeRewardTransfer(address _to, uint256 _amount)
        internal 
    {
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        if (_amount > 0) {
            if (_amount > rewardBal) {
                rewardToken.transfer(_to, rewardBal);
            } else {
                rewardToken.transfer(_to, _amount);
            }
        }
    }

    /**
     * @dev Calculate remaining blocks left according to current reward supply and rate
     * Useful for contract owner to either re-supply or migrate to an alternate reward solution
     */
    function rewardBlocksLeft() 
        public
        view
        returns (uint256)
    {
        uint256 balance = rewardToken.balanceOf(address(this));
        return balance.div(rewardPerBlock);
    }
}