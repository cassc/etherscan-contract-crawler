// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { ReentrancyGuard } from "./external/openzeppelin/ReentrancyGuard.sol";

import { RewardsDistribution } from "./abstract/RewardsDistribution.sol";
import { StableMath } from "./libraries/StableMath.sol";
import { SafeERC20, IERC20 } from "./libraries/SafeERC20.sol";
import { Parameterized } from "./Parameterized.sol";

/**
 * @title  SynapseStaking
 * @notice Rewards stakers of SNP token and a given LP token with rewards in form of SNP token, on a pro-rata basis.
 * @dev    Uses an ever increasing 'rewardPerTokenStored' variable to distribute rewards
 *         each time a write action is called in the contract. This allows for passive reward accrual.
 */
contract SynapseStaking is RewardsDistribution, ReentrancyGuard, Parameterized {
    using StableMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice stake/reward token address
    address public tokenAddress;
    /// @notice LP stake token address
    address public liquidityAddress;
    /// @notice vesting contract address
    address public vestingAddress;

    /// @notice timestamp for current period finish
    uint256 public periodFinish;
    /// @notice timestamp for current super period finish
    uint256 public superPeriodFinish;

    struct Data {
        uint256 depositedTokens; // deposited tokens amount
        uint256 depositedLiquidity; // deposited lp amount
        uint256 totalRewardsAdded; // accumulated amount of rewards added to token and liquidity staking
        uint256 totalRewardsClaimed; // accumulated amount of rewards claimed
        uint256 totalRewardsFromFees; // accumulated amount of rewards collected from fee-on-transfer
    }

    Data public data;

    struct StakingData {
        uint256 rewardRate; // rewardRate for the rest of the period
        uint256 superRewardRate; // superRewardRate for the rest of the super period
        uint256 lastUpdateTime; // last time any user took action
        uint256 lastSuperUpdateTime; // last time super staker took action
        uint256 rewardPerTokenStored; // accumulated per token reward since the beginning of time
        uint256 superRewardPerTokenStored; // super accumulated per token reward since the beginning of time
        uint256 stakedTokens; // amount of tokens that is used in reward per token calculation
        uint256 stakedSuperTokens; // amount of tokens that is used in super reward per token calculation
    }

    StakingData public tokenStaking;
    StakingData public lpStaking;

    struct Stake {
        uint256 stakeStart; // timestamp of stake creation
        uint256 superStakerPossibleAt; // timestamp after which user can claim super staker status
        //
        uint256 rewardPerTokenPaid; // user accumulated per token rewards
        uint256 superRewardPerTokenPaid; // user accumulated per token super staker rewards
        //
        uint256 tokens; // total tokens staked by user snp or lp
        uint256 rewards; // current not-claimed rewards from last update
        //
        uint256 withdrawalPossibleAt; // timestamp after which stake can be removed without fee
        bool isWithdrawing; // true = user call to remove stake
        bool isSuperStaker; // true = user is super staker
    }

    /// @dev each holder have one stake
    /// @notice token stakes storage
    mapping(address => Stake) public tokenStake;
    /// @notice LP token stakes storage
    mapping(address => Stake) public liquidityStake;

    /// @dev events
    event Claimed(address indexed user, uint256 amount);
    event StakeAdded(address indexed user, uint256 amount);
    event StakeLiquidityAdded(address indexed user, uint256 amount);
    event StakeRemoveRequested(address indexed user);
    event StakeLiquidityRemoveRequested(address indexed user);
    event StakeRemoved(address indexed user, uint256 amount);
    event StakeLiquidityRemoved(address indexed user, uint256 amount);
    event Recalculation(uint256 reward, uint256 lpReward);
    event SuperRecalculation(uint256 superReward, uint256 superLpReward);

    /**
     * @param _timeToSuper time needed to become a super staker
     * @param _timeToUnstake time needed to unstake without fee
     */
    constructor(uint256 _timeToSuper, uint256 _timeToUnstake) {
        timeToSuper.value = _timeToSuper;
        timeToUnstake.value = _timeToUnstake;
        timeToSuper.lastChange = block.timestamp;
        timeToUnstake.lastChange = block.timestamp;
        timeToSuper.minDelay = WEEK;
        timeToUnstake.minDelay = WEEK;
        unstakeFee.value = 1000;
    }

    /**
     * @dev One time initialization function
     * @param _token SNP token address
     * @param _liquidity SNP/USDC LP token address
     * @param _vesting public vesting contract address
     */
    function init(
        address _token,
        address _liquidity,
        address _vesting
    ) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        require(_liquidity != address(0), "_liquidity address cannot be 0");
        require(_vesting != address(0), "_vesting address cannot be 0");
        require(tokenAddress == address(0), "Init already done");
        tokenAddress = _token;
        liquidityAddress = _liquidity;
        vestingAddress = _vesting;
    }

    /**
     * @dev Updates the reward for a given address,
     *      for token and LP pool, before executing function
     * @param _account address of staker for which rewards will be updated
     */
    modifier updateRewards(address _account) {
        _updateReward(_account, false);
        _updateReward(_account, true);
        _;
    }

    /**
     * @dev Updates the reward for a given address,
     *      for given pool, before executing function
     * @param _account address for which rewards will be updated
     * @param _lp true=lpStaking, false=tokenStaking
     */
    modifier updateReward(address _account, bool _lp) {
        _updateReward(_account, _lp);
        _;
    }

    /**
     * @dev Updates the super rewards for a given address,
     *      for token and LP pool, before executing function
     * @param _account address of super staker for which super rewards will be updated
     */
    modifier updateSuperRewards(address _account) {
        bool success = _updateSuperReward(_account, false);
        success = _updateSuperReward(_account, true) || success;
        if (success) {
            _calculateSuperRewardAmount();
        }
        _;
    }

    /**
     * @dev guards that the given address has selected stake
     * @param _account address to check
     * @param _lp true=lpStaking, false=tokenStaking
     */
    modifier hasPoolStake(address _account, bool _lp) {
        bool accountHasStake = _lp ? (liquidityStake[_account].tokens > 0) : (tokenStake[_account].tokens > 0);
        require(accountHasStake, "Nothing staked");
        _;
    }

    /**
     * @dev guards that the msg.sender has token or LP stake
     */
    modifier hasStake() {
        require((liquidityStake[msg.sender].tokens > 0) || (tokenStake[msg.sender].tokens > 0), "Nothing staked");
        _;
    }

    /**
     * @dev guards that the given address can be a super staker in selected stake
     * @param _account address to check
     * @param _lp true=lpStaking, false=tokenStaking
     */
    modifier canBeSuper(address _account, bool _lp) {
        Stake memory s = _lp ? liquidityStake[_account] : tokenStake[_account];
        require(!s.isWithdrawing, "Cannot when withdrawing");
        require(!s.isSuperStaker, "Already super staker");
        require(block.timestamp >= s.superStakerPossibleAt, "Too soon");
        _;
    }

    /**
     * @dev checks if the msg.sender can withdraw requested unstake
     */
    modifier canUnstake() {
        require(_canUnstake(), "Cannot unstake");
        _;
    }

    /**
     * @dev checks if for the msg.sender there is possibility to
     *      withdraw staked tokens without fee.
     */
    modifier cantUnstake() {
        require(!_canUnstake(), "Unstake first");
        _;
    }

    /***************************************
                    ACTIONS
    ****************************************/

    /**
     * @dev Updates reward in selected pool
     * @param _account address for which rewards will be updated
     * @param _lp true=lpStaking, false=tokenStaking
     */
    function _updateReward(address _account, bool _lp) internal {
        uint256 newRewardPerTokenStored = currentRewardPerTokenStored(_lp);
        // if statement protects against loss in initialization case
        if (newRewardPerTokenStored > 0) {
            StakingData storage sd = _lp ? lpStaking : tokenStaking;
            sd.rewardPerTokenStored = newRewardPerTokenStored;
            sd.lastUpdateTime = lastTimeRewardApplicable();

            // setting of personal vars based on new globals
            if (_account != address(0)) {
                Stake storage s = _lp ? liquidityStake[_account] : tokenStake[_account];
                if (!s.isWithdrawing) {
                    s.rewards = _earned(_account, _lp);
                    s.rewardPerTokenPaid = newRewardPerTokenStored;
                }
            }
        }
    }

    /**
     * @dev Updates super reward in selected pool
     * @param _account address of super staker for which super rewards will be updated
     * @param _lp true=lpStaking, false=tokenStaking
     */
    function _updateSuperReward(address _account, bool _lp) internal returns (bool success) {
        Stake storage s = _lp ? liquidityStake[_account] : tokenStake[_account];
        // save gas for non super stakers
        if (s.isSuperStaker || _account == address(0)) {
            uint256 newSuperRewardPerTokenStored = currentSuperRewardPerTokenStored(_lp);
            // if statement protects against loss in initialization case
            if (newSuperRewardPerTokenStored > 0) {
                StakingData storage sd = _lp ? lpStaking : tokenStaking;
                sd.superRewardPerTokenStored = newSuperRewardPerTokenStored;
                sd.lastSuperUpdateTime = lastTimeSuperRewardApplicable();

                // setting of personal vars based on new globals
                if (_account != address(0)) {
                    // setting of personal vars based on new globals
                    if (!s.isWithdrawing) {
                        s.rewards = _earnedSuper(_account, _lp);
                        s.superRewardPerTokenPaid = newSuperRewardPerTokenStored;
                    }
                }
            }

            success = true;
        }
    }

    /**
     * @dev Add tokens for staking from vesting contract
     * @param _account address that call claimAndStake in vesting
     * @param _amount number of tokens sent to contract
     */
    function onClaimAndStake(address _account, uint256 _amount)
        external
        nonReentrant
        updateReward(_account, false)
        updateSuperRewards(_account)
    {
        require(msg.sender == vestingAddress, "Only vesting contract");
        require(!tokenStake[_account].isWithdrawing, "Cannot when withdrawing");
        require(_amount > 0, "Zero Amount");

        Stake storage s = tokenStake[_account];
        StakingData storage sd = tokenStaking;

        if (s.stakeStart == 0) {
            // new stake
            s.stakeStart = block.timestamp;
            s.superStakerPossibleAt = s.stakeStart + timeToSuper.value;
        }

        // update account stake data
        s.tokens += _amount;

        // update pool staking data
        sd.stakedTokens += _amount;
        if (s.isSuperStaker) {
            sd.stakedSuperTokens += _amount;
        }

        // update global data
        data.depositedTokens += _amount;

        emit StakeAdded(_account, _amount);
    }

    /**
     * @dev Add tokens to staking contract
     * @param _amount of tokens to stake
     */
    function addTokenStake(uint256 _amount) external {
        _addStake(msg.sender, _amount, false);
        emit StakeAdded(msg.sender, _amount);
    }

    /**
     * @dev Add tokens to staking contract by using permit to set allowance
     * @param _amount of tokens to stake
     * @param _deadline of permit signature
     * @param _approveMax allowance for the token
     */
    function addTokenStakeWithPermit(
        uint256 _amount,
        uint256 _deadline,
        bool _approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint256 value = _approveMax ? type(uint256).max : _amount;
        IERC20(tokenAddress).permit(msg.sender, address(this), value, _deadline, v, r, s);
        _addStake(msg.sender, _amount, false);
        emit StakeAdded(msg.sender, _amount);
    }

    /**
     * @dev Add liquidity tokens to staking contract
     * @param _amount of LP tokens to stake
     */
    function addLiquidityStake(uint256 _amount) external {
        _addStake(msg.sender, _amount, true);
        emit StakeLiquidityAdded(msg.sender, _amount);
    }

    /**
     * @dev Add liquidity tokens to staking contract
     * @param _amount of tokens to stake
     * @param _deadline of permit signature
     * @param _approveMax allowance for the token
     */
    function addLiquidityStakeWithPermit(
        uint256 _amount,
        uint256 _deadline,
        bool _approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint256 value = _approveMax ? type(uint256).max : _amount;
        IERC20(liquidityAddress).permit(msg.sender, address(this), value, _deadline, v, r, s);
        _addStake(msg.sender, _amount, true);
        emit StakeLiquidityAdded(msg.sender, _amount);
    }

    /**
     * @dev Internal add stake function
     * @param _account selected staked tokens are credited to this address
     * @param _amount of staked tokens
     * @param _lp true=LP token, false=SNP token
     */
    function _addStake(
        address _account,
        uint256 _amount,
        bool _lp
    ) internal nonReentrant updateReward(_account, _lp) updateSuperRewards(_account) {
        require(_amount > 0, "Zero Amount");
        Stake storage s = _lp ? liquidityStake[_account] : tokenStake[_account];
        require(!s.isWithdrawing, "Cannot when withdrawing");

        address token = _lp ? liquidityAddress : tokenAddress;

        // check for fee-on-transfer and proceed with received amount
        _amount = _transferFrom(token, msg.sender, _amount);

        if (s.stakeStart == 0) {
            // new stake
            s.stakeStart = block.timestamp;
            s.superStakerPossibleAt = s.stakeStart + timeToSuper.value;
        }

        StakingData storage sd = _lp ? lpStaking : tokenStaking;

        // update account stake data
        s.tokens += _amount;

        // update pool staking data
        sd.stakedTokens += _amount;
        if (s.isSuperStaker) {
            sd.stakedSuperTokens += _amount;
        }

        // update global data
        if (_lp) {
            data.depositedLiquidity += _amount;
        } else {
            data.depositedTokens += _amount;
        }
    }

    /**
     * @dev Restake earned tokens and add them to token stake (instead of claiming)
     *      If have LP stake but not token stake - token stake will be created.
     */
    function restake() external hasStake updateRewards(msg.sender) updateSuperRewards(msg.sender) {
        Stake storage ts = tokenStake[msg.sender];
        Stake storage ls = liquidityStake[msg.sender];
        require(!ts.isWithdrawing, "Cannot when withdrawing");

        uint256 rewards = ts.rewards + ls.rewards;
        require(rewards > 0, "Nothing to restake");

        delete ts.rewards;
        delete ls.rewards;

        if (ts.stakeStart == 0) {
            // new stake
            ts.stakeStart = block.timestamp;
            ts.superStakerPossibleAt = ts.stakeStart + timeToSuper.value;
        }

        // update account stake data
        ts.tokens += rewards;

        // update pool staking data
        tokenStaking.stakedTokens += rewards;
        if (ts.isSuperStaker) {
            tokenStaking.stakedSuperTokens += rewards;
        }

        data.totalRewardsClaimed += rewards;
        data.depositedTokens += rewards;

        emit Claimed(msg.sender, rewards);
        emit StakeAdded(msg.sender, rewards);
    }

    /**
     * @dev Claims rewards for the msg.sender.
     */
    function claim() external {
        _claim(msg.sender, msg.sender);
    }

    /**
     * @dev Claim msg.sender rewards to provided address
     * @param _recipient address where claimed tokens should be sent
     */
    function claimTo(address _recipient) external {
        _claim(msg.sender, _recipient);
    }

    /**
     * @dev Internal claim function. First updates rewards in normal and super pools
     *      and then transfers.
     * @param _account claim rewards for this address
     * @param _recipient claimed tokens are sent to this address
     */
    function _claim(address _account, address _recipient) internal nonReentrant hasStake updateRewards(_account) updateSuperRewards(_account) {
        uint256 rewards = tokenStake[_account].rewards + liquidityStake[_account].rewards;

        require(rewards > 0, "Nothing to claim");

        delete tokenStake[_account].rewards;
        delete liquidityStake[_account].rewards;

        data.totalRewardsClaimed += rewards;
        _transfer(tokenAddress, _recipient, rewards);

        emit Claimed(_account, rewards);
    }

    /**
     * @dev Request unstake for deposited tokens. Marks user token stake as withdrawing,
     *      and start withdrawing period.
     */
    function requestUnstake() external {
        _requestUnstake(msg.sender, false);
        emit StakeRemoveRequested(msg.sender);
    }

    /**
     * @dev Request unstake for deposited LP tokens. Marks user lp stake as withdrawing
     *      and start withdrawing period.
     */
    function requestUnstakeLp() external {
        _requestUnstake(msg.sender, true);
        emit StakeLiquidityRemoveRequested(msg.sender);
    }

    /**
     * @dev Internal request unstake function. Update normal and super rewards for the user first.
     * @param _account User address
     * @param _lp true=it is LP stake
     */
    function _requestUnstake(address _account, bool _lp)
        internal
        hasPoolStake(_account, _lp)
        updateReward(_account, _lp)
        updateSuperRewards(_account)
    {
        Stake storage s = _lp ? liquidityStake[_account] : tokenStake[_account];
        require(!s.isWithdrawing, "Cannot when withdrawing");
        StakingData storage sd = _lp ? lpStaking : tokenStaking;

        // update account stake data
        s.isWithdrawing = true;
        s.withdrawalPossibleAt = block.timestamp + timeToUnstake.value;

        // update pool staking data
        sd.stakedTokens -= s.tokens;
        if (s.isSuperStaker) {
            delete s.isSuperStaker;
            sd.stakedSuperTokens -= s.tokens;
        }
    }

    /**
     * @dev Withdraw stake for msg.sender from both stakes (if possible)
     */
    function unstake() external nonReentrant hasStake canUnstake {
        bool success;
        uint256 reward;
        uint256 tokens;
        uint256 rewards;

        (reward, success) = _unstake(msg.sender, false);
        rewards += reward;
        if (success) {
            tokens += tokenStake[msg.sender].tokens;
            data.depositedTokens -= tokenStake[msg.sender].tokens;
            emit StakeRemoved(msg.sender, tokenStake[msg.sender].tokens);
            delete tokenStake[msg.sender];
        }

        (reward, success) = _unstake(msg.sender, true);
        rewards += reward;
        if (success) {
            delete liquidityStake[msg.sender];
        }

        if (tokens + rewards > 0) {
            _transfer(tokenAddress, msg.sender, tokens + rewards);
            if (rewards > 0) {
                emit Claimed(msg.sender, rewards);
            }
        }
    }

    /**
     * @dev Internal unstake function, withdraw staked LP tokens
     * @param _account address of account to transfer LP tokens
     * @param _lp true = LP stake
     * @return stake rewards amount
     * @return bool true if success
     */
    function _unstake(address _account, bool _lp) internal returns (uint256, bool) {
        Stake memory s = _lp ? liquidityStake[_account] : tokenStake[_account];
        if (!s.isWithdrawing) return (0, false);
        if (s.withdrawalPossibleAt > block.timestamp) return (0, false);

        data.totalRewardsClaimed += s.rewards;

        // only LP stake
        if (_lp && s.tokens > 0) {
            data.depositedLiquidity -= s.tokens;
            _transfer(liquidityAddress, _account, s.tokens);
            emit StakeLiquidityRemoved(_account, s.tokens);
        }

        return (s.rewards, true);
    }

    /**
     * @dev Unstake requested stake at any time accepting 10% penalty fee
     */
    function unstakeWithFee() external nonReentrant hasStake cantUnstake {
        Stake memory ts = tokenStake[msg.sender];
        Stake memory ls = liquidityStake[msg.sender];
        uint256 tokens;
        uint256 rewards;

        if (ls.isWithdrawing) {
            uint256 lpTokens = _minusFee(ls.tokens); //remaining tokens remain on the contract

            rewards += ls.rewards;

            data.totalRewardsClaimed += ls.rewards;
            data.depositedLiquidity -= ls.tokens;
            emit StakeLiquidityRemoved(msg.sender, ls.tokens);

            if (lpTokens > 0) {
                _transfer(liquidityAddress, msg.sender, lpTokens);
            }

            delete liquidityStake[msg.sender];
        }

        if (ts.isWithdrawing) {
            tokens = _minusFee(ts.tokens); // remaining tokens goes to Super Stakers

            rewards += ts.rewards;

            data.totalRewardsClaimed += ts.rewards;
            data.depositedTokens -= ts.tokens;
            emit StakeRemoved(msg.sender, ts.tokens);

            delete tokenStake[msg.sender];
        }

        if (tokens + rewards > 0) {
            _transfer(tokenAddress, msg.sender, tokens + rewards);
            if (rewards > 0) {
                emit Claimed(msg.sender, rewards);
            }
        }
    }

    /**
     * @dev Set Super Staker status for token pool stake if possible.
     */
    function setSuperToken() external {
        _setSuper(msg.sender, false);
    }

    /**
     * @dev Set Super Staker status for LP pool stake if possible.
     */
    function setSuperLp() external {
        _setSuper(msg.sender, true);
    }

    /**
     * @dev Set Super Staker status if possible for selected pool.
     *      Update super reward pools.
     * @param _account address of account to set super
     * @param _lp true=LP stake super staker, false=token stake super staker
     */
    function _setSuper(address _account, bool _lp)
        internal
        hasPoolStake(_account, _lp)
        canBeSuper(_account, _lp)
        updateSuperRewards(address(0))
    {
        Stake storage s = _lp ? liquidityStake[_account] : tokenStake[_account];
        StakingData storage sd = _lp ? lpStaking : tokenStaking;

        sd.stakedSuperTokens += s.tokens;

        s.isSuperStaker = true;
        s.superRewardPerTokenPaid = sd.superRewardPerTokenStored;
    }

    /***************************************
                    GETTERS
    ****************************************/

    /**
     * @dev Gets the last applicable timestamp for this reward period
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return StableMath.min(block.timestamp, periodFinish);
    }

    /**
     * @dev Gets the last applicable timestamp for this super reward period
     */
    function lastTimeSuperRewardApplicable() public view returns (uint256) {
        return StableMath.min(block.timestamp, superPeriodFinish);
    }

    /**
     * @dev Calculates the amount of unclaimed rewards per token since last update,
     *      and sums with stored to give the new cumulative reward per token
     * @param _lp true=lpStaking, false=tokenStaking
     * @return 'Reward' per staked token
     */
    function currentRewardPerTokenStored(bool _lp) public view returns (uint256) {
        StakingData memory sd = _lp ? lpStaking : tokenStaking;
        uint256 stakedTokens = sd.stakedTokens;
        uint256 rewardPerTokenStored = sd.rewardPerTokenStored;
        // If there is no staked tokens, avoid div(0)
        if (stakedTokens == 0) {
            return (rewardPerTokenStored);
        }
        // new reward units to distribute = rewardRate * timeSinceLastUpdate
        uint256 timeDelta = lastTimeRewardApplicable() - sd.lastUpdateTime;
        uint256 rewardUnitsToDistribute = sd.rewardRate * timeDelta;
        // new reward units per token = (rewardUnitsToDistribute * 1e18) / stakedTokens
        uint256 unitsToDistributePerToken = rewardUnitsToDistribute.divPrecisely(stakedTokens);
        // return summed rate
        return (rewardPerTokenStored + unitsToDistributePerToken);
    }

    /**
     * @dev Calculates the amount of unclaimed super rewards per token since last update,
     * and sums with stored to give the new cumulative reward per token
     * @param _lp true=lpStaking, false=tokenStaking
     * @return 'Reward' per staked token
     */
    function currentSuperRewardPerTokenStored(bool _lp) public view returns (uint256) {
        StakingData memory sd = _lp ? lpStaking : tokenStaking;
        uint256 stakedSuperTokens = sd.stakedSuperTokens;
        uint256 superRewardPerTokenStored = sd.superRewardPerTokenStored;
        // If there is no staked tokens, avoid div(0)
        if (stakedSuperTokens == 0) {
            return (superRewardPerTokenStored);
        }

        // new reward units to distribute = superRewardRate * timeSinceLastSuperUpdate
        uint256 timeDelta = lastTimeSuperRewardApplicable() - sd.lastSuperUpdateTime;
        uint256 rewardUnitsToDistribute = sd.superRewardRate * timeDelta;
        // new reward units per token = (rewardUnitsToDistribute * 1e18) / totalSuperTokens
        uint256 unitsToDistributePerToken = rewardUnitsToDistribute.divPrecisely(stakedSuperTokens);

        // return summed rate
        return (superRewardPerTokenStored + unitsToDistributePerToken);
    }

    /**
     * @dev Calculates the amount of unclaimed rewards a user has earned
     * @param _account user address
     * @param _lp true=liquidityStake, false=tokenStake
     * @return Total reward amount earned
     */
    function _earned(address _account, bool _lp) internal view returns (uint256) {
        Stake memory s = _lp ? liquidityStake[_account] : tokenStake[_account];
        if (s.isWithdrawing) return s.rewards;
        // current rate per token - rate user previously received
        uint256 rewardPerTokenStored = currentRewardPerTokenStored(_lp);
        uint256 userRewardDelta = rewardPerTokenStored - s.rewardPerTokenPaid;
        uint256 userNewReward = s.tokens.mulTruncate(userRewardDelta);
        // add to previous rewards
        return (s.rewards + userNewReward);
    }

    /**
     * @dev Calculates the amount of unclaimed super rewards a user has earned
     * @param _account user address
     * @param _lp true=liquidityStake, false=tokenStake
     * @return Total reward amount earned
     */
    function _earnedSuper(address _account, bool _lp) internal view returns (uint256) {
        Stake memory s = _lp ? liquidityStake[_account] : tokenStake[_account];
        if (!s.isSuperStaker || s.isWithdrawing) return s.rewards;
        // current rate per token - rate user previously received
        uint256 superRewardPerTokenStored = currentSuperRewardPerTokenStored(_lp);
        uint256 superRewardDelta = superRewardPerTokenStored - s.superRewardPerTokenPaid;
        uint256 userNewSuperReward = s.tokens.mulTruncate(superRewardDelta);
        // add to previous rewards
        return (s.rewards + userNewSuperReward);
    }

    /**
     * @dev Calculates the claimable amounts for token and lp stake from normal and super rewards
     * @param _account user address
     * @return token - claimable reward amount for token stake
     * @return lp - claimable reward amount for lp stake
     */
    function claimable(address _account) external view returns (uint256 token, uint256 lp) {
        token = _earned(_account, false) + _earnedSuper(_account, false) - tokenStake[_account].rewards;
        lp = _earned(_account, true) + _earnedSuper(_account, true) - liquidityStake[_account].rewards;
    }

    /**
     * @dev Check if staker can set super staker status on token or LP stake
     * @param _account address to check
     * @return token true if can set super staker on token stake
     * @return lp true if can set super staker on LP stake
     */
    function canSetSuper(address _account) external view returns (bool token, bool lp) {
        Stake memory ts = tokenStake[_account];
        Stake memory ls = liquidityStake[_account];
        if (ts.tokens > 0 && block.timestamp >= ts.superStakerPossibleAt && !ts.isSuperStaker && !ts.isWithdrawing) token = true;
        if (ls.tokens > 0 && block.timestamp >= ls.superStakerPossibleAt && !ls.isSuperStaker && !ls.isWithdrawing) lp = true;
    }

    /**
     * @dev internal view to check if msg.sender can unstake
     * @return true if user requested unstake and time for unstake has passed
     */
    function _canUnstake() private view returns (bool) {
        return
            (liquidityStake[msg.sender].isWithdrawing && block.timestamp >= liquidityStake[msg.sender].withdrawalPossibleAt) ||
            (tokenStake[msg.sender].isWithdrawing && block.timestamp >= tokenStake[msg.sender].withdrawalPossibleAt);
    }

    /**
     * @dev external view to check if address can stake tokens
     * @return true if user can stake tokens
     */
    function canStakeTokens(address _account) external view returns (bool) {
        return !tokenStake[_account].isWithdrawing;
    }

    /**
     * @dev external view to check if address can stake lp
     * @return true if user can stake lp
     */
    function canStakeLp(address _account) external view returns (bool) {
        return !liquidityStake[_account].isWithdrawing;
    }

    /***************************************
                    REWARDER
    ****************************************/

    /**
     * @dev Notifies the contract that new rewards have been added.
     *      Calculates an updated rewardRate based on the rewards in period.
     * @param _reward Units of SNP token that have been added to the token pool
     * @param _lpReward Units of SNP token that have been added to the lp pool
     */
    function notifyRewardAmount(uint256 _reward, uint256 _lpReward) external onlyRewardsDistributor updateRewards(address(0)) {
        uint256 currentTime = block.timestamp;

        // pull tokens
        require(_transferFrom(tokenAddress, msg.sender, _reward + _lpReward) == _reward + _lpReward, "Exclude Rewarder from fee");

        // If previous period over, reset rewardRate
        if (currentTime >= periodFinish) {
            tokenStaking.rewardRate = _reward / WEEK;
            lpStaking.rewardRate = _lpReward / WEEK;
        }
        // If additional reward to existing period, calc sum
        else {
            uint256 remaining = periodFinish - currentTime;

            uint256 leftoverReward = remaining * tokenStaking.rewardRate;
            tokenStaking.rewardRate = (_reward + leftoverReward) / WEEK;

            uint256 leftoverLpReward = remaining * lpStaking.rewardRate;
            lpStaking.rewardRate = (_lpReward + leftoverLpReward) / WEEK;
        }

        tokenStaking.lastUpdateTime = currentTime;
        lpStaking.lastUpdateTime = currentTime;
        periodFinish = currentTime + WEEK;

        data.totalRewardsAdded += _reward + _lpReward;

        emit Recalculation(_reward, _lpReward);
    }

    /***************************************
                    SUPER STAKER
    ****************************************/

    /**
     * @dev Notifies the contract that new super rewards have been added based on the collected fee.
     *      Calculates an updated superRewardRate based on the rewards in period.
     *      Function can be triggered by any super staker once a day.
     */
    function _calculateSuperRewardAmount() internal {
        uint256 currentTime = block.timestamp;
        // Do nothing if less then a day from last calculation, save gas
        uint256 lastTime = superPeriodFinish > 0 ? superPeriodFinish - (MONTH - 1 days) : 0;
        if (currentTime >= lastTime) {
            uint256 contractBalance = _balance(tokenAddress, address(this));
            uint256 feesCollected = contractBalance -
                data.depositedTokens -
                (data.totalRewardsAdded + data.totalRewardsFromFees - data.totalRewardsClaimed);
            data.totalRewardsFromFees += feesCollected;

            uint256 superRewards;
            unchecked {
                superRewards = feesCollected / 2;
            }

            // If previous period over, reset rewardRate
            if (currentTime >= superPeriodFinish) {
                tokenStaking.superRewardRate = superRewards / MONTH;
                lpStaking.superRewardRate = superRewards / MONTH;
            }
            // If additional reward to existing period, calc sum
            else {
                uint256 remaining = superPeriodFinish - currentTime;

                uint256 leftoverSuperReward = remaining * tokenStaking.superRewardRate;
                tokenStaking.superRewardRate = (superRewards + leftoverSuperReward) / MONTH;

                uint256 leftoverSuperLpReward = remaining * lpStaking.superRewardRate;
                lpStaking.superRewardRate = (superRewards + leftoverSuperLpReward) / MONTH;
            }

            tokenStaking.lastSuperUpdateTime = currentTime;
            lpStaking.lastSuperUpdateTime = currentTime;
            superPeriodFinish = currentTime + MONTH;

            emit SuperRecalculation(superRewards, superRewards);
        }
    }

    /***************************************
                    TOKEN
    ****************************************/

    /**
     * @dev internal ERC20 tools
     */

    function _balance(address token, address user) internal view returns (uint256) {
        return IERC20(token).balanceOf(user);
    }

    function _transferFrom(
        address token,
        address from,
        uint256 amount
    ) internal returns (uint256) {
        return IERC20(token).safeTransferFromDeluxe(from, amount);
    }

    function _transfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        IERC20(token).safeTransfer(to, amount);
    }
}