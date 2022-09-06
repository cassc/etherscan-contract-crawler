// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";
import {SafeCast} from "SafeCast.sol";
import {Math} from "Math.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";

import {VoteToken} from "VoteToken.sol";
import {ITrueDistributor} from "ITrueDistributor.sol";
import {StkClaimableContract} from "StkClaimableContract.sol";
import {IPauseableContract} from "IPauseableContract.sol";

/**
 * @title stkTRU
 * @dev Staking contract for TrueFi
 * TRU is staked and stored in the contract
 * stkTRU is minted when staking
 * Holders of stkTRU accrue rewards over time
 * Rewards are paid in TRU and tfUSD
 * stkTRU can be used to vote in governance
 * stkTRU can be used to rate and approve loans
 */
contract StkTruToken is VoteToken, StkClaimableContract, IPauseableContract, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 private constant PRECISION = 1e30;
    uint256 private constant MIN_DISTRIBUTED_AMOUNT = 100e8;
    uint256 private constant MAX_COOLDOWN = 100 * 365 days;
    uint256 private constant MAX_UNSTAKE_PERIOD = 100 * 365 days;
    uint32 private constant SCHEDULED_REWARDS_BATCH_SIZE = 32;

    struct FarmRewards {
        // track overall cumulative rewards
        uint256 cumulativeRewardPerToken;
        // track previous cumulate rewards for accounts
        mapping(address => uint256) previousCumulatedRewardPerToken;
        // track claimable rewards for accounts
        mapping(address => uint256) claimableReward;
        // track total rewards
        uint256 totalClaimedRewards;
        uint256 totalFarmRewards;
    }

    struct ScheduledTfUsdRewards {
        uint64 timestamp;
        uint96 amount;
    }

    // ================ WARNING ==================
    // ===== THIS CONTRACT IS INITIALIZABLE ======
    // === STORAGE VARIABLES ARE DECLARED BELOW ==
    // REMOVAL OR REORDER OF VARIABLES WILL RESULT
    // ========= IN STORAGE CORRUPTION ===========

    IERC20 public tru;
    IERC20 public tfusd;
    ITrueDistributor public distributor;
    address public liquidator;

    uint256 public stakeSupply;

    mapping(address => uint256) internal cooldowns;
    uint256 public cooldownTime;
    uint256 public unstakePeriodDuration;

    mapping(IERC20 => FarmRewards) public farmRewards;

    uint32[] public sortedScheduledRewardIndices;
    ScheduledTfUsdRewards[] public scheduledRewards;
    uint256 public undistributedTfusdRewards;
    uint32 public nextDistributionIndex;

    mapping(address => bool) public whitelistedFeePayers;

    mapping(address => uint256) public receivedDuringCooldown;

    // allow pausing of deposits
    bool public pauseStatus;

    IERC20 public feeToken;

    Checkpoint[] internal _totalSupplyCheckpoints;

    // ======= STORAGE DECLARATION END ============

    event Stake(address indexed staker, uint256 amount);
    event Unstake(address indexed staker, uint256 burntAmount);
    event Claim(address indexed who, IERC20 indexed token, uint256 amountClaimed);
    event Withdraw(uint256 amount);
    event Cooldown(address indexed who, uint256 endTime);
    event CooldownTimeChanged(uint256 newUnstakePeriodDuration);
    event UnstakePeriodDurationChanged(uint256 newUnstakePeriodDuration);
    event FeePayerWhitelistingStatusChanged(address payer, bool status);
    event PauseStatusChanged(bool pauseStatus);
    event FeeTokenChanged(IERC20 token);
    event LiquidatorChanged(address liquidator);

    /**
     * Get TRU from distributor
     */
    modifier distribute() {
        // pull TRU from distributor
        // do not pull small amounts to save some gas
        // only pull if there is distribution and distributor farm is set to this farm
        if (distributor.nextDistribution() >= MIN_DISTRIBUTED_AMOUNT && distributor.farm() == address(this)) {
            distributor.distribute();
        }
        _;
    }

    /**
     * Update all rewards when an account changes state
     * @param account Account to update rewards for
     */
    modifier update(address account) {
        _update(account);
        _;
    }

    function _update(address account) internal {
        updateTotalRewards(tru);
        updateClaimableRewards(tru, account);
        updateTotalRewards(tfusd);
        updateClaimableRewards(tfusd, account);
        updateTotalRewards(feeToken);
        updateClaimableRewards(feeToken, account);
    }

    /**
     * Update rewards for a specific token when an account changes state
     * @param account Account to update rewards for
     * @param token Token to update rewards for
     */
    modifier updateRewards(address account, IERC20 token) {
        if (token == tru || token == tfusd || token == feeToken) {
            updateTotalRewards(token);
            updateClaimableRewards(token, account);
        }
        _;
    }

    constructor() {
        initalized = true;
    }

    /**
     * @dev Initialize contract and set default values
     * @param _tru TRU token
     * @param _tfusd tfUSD token
     * @param _feeToken Token for fees, currently tfUSDC
     * @param _distributor Distributor for this contract
     * @param _liquidator Liquidator for staked TRU
     */
    function initialize(
        IERC20 _tru,
        IERC20 _tfusd,
        IERC20 _feeToken,
        ITrueDistributor _distributor,
        address _liquidator
    ) public {
        require(!initalized, "StkTruToken: Already initialized");
        require(address(_tru) != address(0), "StkTruToken: TRU token address must not be 0");
        require(address(_tfusd) != address(0), "StkTruToken: tfUSD token address must not be 0");
        require(address(_feeToken) != address(0), "StkTruToken: fee token address must not be 0");
        tru = _tru;
        tfusd = _tfusd;
        feeToken = _feeToken;
        distributor = _distributor;
        liquidator = _liquidator;

        cooldownTime = 14 days;
        unstakePeriodDuration = 2 days;

        initTotalSupplyCheckpoints();

        owner_ = msg.sender;
        initalized = true;
    }

    function initTotalSupplyCheckpoints() public onlyOwner {
        require(_totalSupplyCheckpoints.length == 0, "StakeTruToken: Total supply checkpoints already initialized");
        _totalSupplyCheckpoints.push(Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint96(totalSupply)}));
    }

    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        _writeTotalSupplyCheckpoint(_add, amount);
    }

    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);
        _writeTotalSupplyCheckpoint(_subtract, amount);
    }

    /**
     * @dev Set tfUSDC address
     * @param _feeToken Address of tfUSDC to be set
     */
    function setFeeToken(IERC20 _feeToken) external onlyOwner {
        require(address(_feeToken) != address(0), "StkTruToken: fee token address must not be 0");
        require(rewardBalance(feeToken) == 0, "StkTruToken: Cannot replace fee token with underlying rewards");
        feeToken = _feeToken;
        emit FeeTokenChanged(_feeToken);
    }

    /**
     * @dev Set liquidator address
     * @param _liquidator Address of liquidator to be set
     */
    function setLiquidator(address _liquidator) external onlyOwner {
        liquidator = _liquidator;
        emit LiquidatorChanged(_liquidator);
    }

    /**
     * @dev Owner can use this function to add new addresses to payers whitelist
     * Only whitelisted payers can call payFee method
     * @param payer Address that is being added to or removed from whitelist
     * @param status New whitelisting status
     */
    function setPayerWhitelistingStatus(address payer, bool status) external onlyOwner {
        whitelistedFeePayers[payer] = status;
        emit FeePayerWhitelistingStatusChanged(payer, status);
    }

    /**
     * @dev Owner can use this function to set cooldown time
     * Cooldown time defines how long a staker waits to unstake TRU
     * @param newCooldownTime New cooldown time for stakers
     */
    function setCooldownTime(uint256 newCooldownTime) external onlyOwner {
        // Avoid overflow
        require(newCooldownTime <= MAX_COOLDOWN, "StkTruToken: Cooldown too large");

        cooldownTime = newCooldownTime;
        emit CooldownTimeChanged(newCooldownTime);
    }

    /**
     * @dev Allow pausing of deposits in case of emergency
     * @param status New deposit status
     */
    function setPauseStatus(bool status) external override onlyOwner {
        pauseStatus = status;
        emit PauseStatusChanged(status);
    }

    /**
     * @dev Owner can set unstake period duration
     * Unstake period defines how long after cooldown a user has to withdraw stake
     * @param newUnstakePeriodDuration New unstake period
     */
    function setUnstakePeriodDuration(uint256 newUnstakePeriodDuration) external onlyOwner {
        require(newUnstakePeriodDuration > 0, "StkTruToken: Unstake period cannot be 0");
        // Avoid overflow
        require(newUnstakePeriodDuration <= MAX_UNSTAKE_PERIOD, "StkTruToken: Unstake period too large");

        unstakePeriodDuration = newUnstakePeriodDuration;
        emit UnstakePeriodDurationChanged(newUnstakePeriodDuration);
    }

    /**
     * @dev Stake TRU for stkTRU
     * Updates rewards when staking
     * @param amount Amount of TRU to stake for stkTRU
     */
    function stake(uint256 amount) external distribute update(msg.sender) {
        require(!pauseStatus, "StkTruToken: Can be called only when not paused");
        _stakeWithoutTransfer(amount);
        tru.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev Unstake stkTRU for TRU
     * Can only unstake when cooldown complete and within unstake period
     * Claims rewards when unstaking
     * @param amount Amount of stkTRU to unstake for TRU
     */
    // slither-disable-next-line reentrancy-eth
    function unstake(uint256 amount) external distribute update(msg.sender) nonReentrant {
        require(amount > 0, "StkTruToken: Cannot unstake 0");

        require(unstakable(msg.sender) >= amount, "StkTruToken: Insufficient balance");
        require(unlockTime(msg.sender) <= block.timestamp, "StkTruToken: Stake on cooldown");

        _claim(tru);
        _claim(tfusd);
        _claim(feeToken);

        uint256 amountToTransfer = (amount * stakeSupply) / totalSupply;

        _burn(msg.sender, amount);
        stakeSupply = stakeSupply - amountToTransfer;

        tru.safeTransfer(msg.sender, amountToTransfer);

        emit Unstake(msg.sender, amount);
    }

    /**
     * @dev Initiate cooldown period
     */
    function cooldown() public {
        cooldowns[msg.sender] = block.timestamp;
        receivedDuringCooldown[msg.sender] = 0;

        emit Cooldown(msg.sender, block.timestamp + cooldownTime);
    }

    /**
     * @dev Withdraw TRU from the contract for liquidation
     * @param amount Amount to withdraw for liquidation
     */
    function withdraw(uint256 amount) external {
        require(msg.sender == liquidator, "StkTruToken: Can be called only by the liquidator");
        require(amount <= stakeSupply, "StkTruToken: Insufficient stake supply");
        stakeSupply = stakeSupply - amount;
        tru.safeTransfer(liquidator, amount);

        emit Withdraw(amount);
    }

    /**
     * @dev View function to get unlock time for an account
     * @param account Account to get unlock time for
     * @return Unlock time for account
     */
    function unlockTime(address account) public view returns (uint256) {
        uint256 cooldownStart = cooldowns[account];
        if (cooldownStart == 0 || cooldownStart + cooldownTime + unstakePeriodDuration < block.timestamp) {
            return type(uint256).max;
        }
        return cooldownStart + cooldownTime;
    }

    /**
     * @dev Give tfUSD as origination fee to stake.this
     * 50% are given immediately and 50% after `endTime` passes
     */
    function payFee(uint256 amount, uint256 endTime) external {
        require(whitelistedFeePayers[msg.sender], "StkTruToken: Can be called only by whitelisted payers");
        require(endTime <= type(uint64).max, "StkTruToken: time overflow");
        require(amount <= type(uint96).max, "StkTruToken: amount overflow");

        tfusd.safeTransferFrom(msg.sender, address(this), amount);
        uint256 halfAmount = amount / 2;
        undistributedTfusdRewards = undistributedTfusdRewards + halfAmount;
        scheduledRewards.push(ScheduledTfUsdRewards({amount: uint96(amount - halfAmount), timestamp: uint64(endTime)}));

        uint32 newIndex = findPositionForTimestamp(endTime);
        insertAt(newIndex, uint32(scheduledRewards.length) - 1);
    }

    /**
     * @dev Claim all rewards
     */
    // slither-disable-next-line reentrancy-eth
    function claim() external distribute update(msg.sender) {
        _claim(tru);
        _claim(tfusd);
        _claim(feeToken);
    }

    /**
     * @dev Claim rewards for specific token
     * Allows account to claim specific token to save gas
     * @param token Token to claim rewards for
     */
    function claimRewards(IERC20 token) external distribute updateRewards(msg.sender, token) {
        require(token == tfusd || token == tru || token == feeToken, "Token not supported for rewards");
        _claim(token);
    }

    /**
     * @dev Claim TRU rewards, transfer in extraStakeAmount, and
     * stake both the rewards and the new amount.
     * Allows account to save more gas by avoiding out-and-back transfers of rewards
     */
    function claimRestake(uint256 extraStakeAmount) external distribute update(msg.sender) {
        uint256 amount = _claimWithoutTransfer(tru) + extraStakeAmount;
        _stakeWithoutTransfer(amount);
        if (extraStakeAmount > 0) {
            tru.safeTransferFrom(msg.sender, address(this), extraStakeAmount);
        }
    }

    /**
     * @dev View to estimate the claimable reward for an account
     * @param account Account to get claimable reward for
     * @param token Token to get rewards for
     * @return claimable rewards for account
     */
    function claimable(address account, IERC20 token) external view returns (uint256) {
        FarmRewards storage rewards = farmRewards[token];
        // estimate pending reward from distributor
        uint256 pendingReward = token == tru ? distributor.nextDistribution() : 0;
        // calculate total rewards (including pending)
        uint256 newTotalFarmRewards = (rewardBalance(token) +
            (pendingReward >= MIN_DISTRIBUTED_AMOUNT ? pendingReward : 0) +
            (rewards.totalClaimedRewards)) * PRECISION;
        // calculate block reward
        uint256 totalBlockReward = newTotalFarmRewards - rewards.totalFarmRewards;
        // calculate next cumulative reward per token
        uint256 nextCumulativeRewardPerToken = rewards.cumulativeRewardPerToken + (totalBlockReward / totalSupply);
        // return claimable reward for this account
        return
            rewards.claimableReward[account] +
            ((balanceOf[account] * (nextCumulativeRewardPerToken - (rewards.previousCumulatedRewardPerToken[account]))) / PRECISION);
    }

    /**
     * @dev max amount of stkTRU than can be unstaked after current cooldown period is over
     */
    function unstakable(address staker) public view returns (uint256) {
        uint256 stakerBalance = balanceOf[staker];

        if (unlockTime(staker) == type(uint256).max) {
            return stakerBalance;
        }

        if (receivedDuringCooldown[staker] > stakerBalance) {
            return 0;
        }
        return stakerBalance - receivedDuringCooldown[staker];
    }

    /**
     * @dev Prior votes votes are calculated as priorVotes * stakedSupply / totalSupply
     * This dilutes voting power when TRU is liquidated
     * @param account Account to get current voting power for
     * @param blockNumber Block to get prior votes at
     * @return prior voting power for account and block
     */
    function getPriorVotes(address account, uint256 blockNumber) public view override returns (uint96) {
        uint96 votes = super.getPriorVotes(account, blockNumber);
        return safe96((stakeSupply * votes) / totalSupply, "StkTruToken: uint96 overflow");
    }

    function getPastVotes(address account, uint256 blockNumber) public view returns (uint96) {
        return super.getPriorVotes(account, blockNumber);
    }

    function getPastTotalSupply(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Current votes are calculated as votes * stakedSupply / totalSupply
     * This dilutes voting power when TRU is liquidated
     * @param account Account to get current voting power for
     * @return voting power for account
     */
    function getCurrentVotes(address account) public view override returns (uint96) {
        uint96 votes = super.getCurrentVotes(account);
        return safe96((stakeSupply * votes) / totalSupply, "StkTruToken: uint96 overflow");
    }

    function decimals() public pure override returns (uint8) {
        return 8;
    }

    function rounding() public pure returns (uint8) {
        return 8;
    }

    function name() public pure override returns (string memory) {
        return "Staked TrueFi";
    }

    function symbol() public pure override returns (string memory) {
        return "stkTRU";
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override distribute update(sender) {
        updateClaimableRewards(tru, recipient);
        updateClaimableRewards(tfusd, recipient);
        updateClaimableRewards(feeToken, recipient);
        // unlockTime returns MAX_UINT256 when there's no ongoing cooldown for the address
        if (unlockTime(recipient) != type(uint256).max) {
            receivedDuringCooldown[recipient] = receivedDuringCooldown[recipient] + amount;
        }
        if (unlockTime(sender) != type(uint256).max) {
            receivedDuringCooldown[sender] = receivedDuringCooldown[sender] - min(receivedDuringCooldown[sender], amount);
        }
        super._transfer(sender, recipient, amount);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Internal claim function
     * Claim rewards for a specific ERC20 token
     * @param token Token to claim rewards for
     */
    function _claim(IERC20 token) internal {
        uint256 rewardToClaim = _claimWithoutTransfer(token);
        if (rewardToClaim > 0) {
            token.safeTransfer(msg.sender, rewardToClaim);
        }
    }

    /**
     * @dev Internal claim function that returns the transfer value
     * Claim rewards for a specific ERC20 token to return in a uint256
     * @param token Token to claim rewards for
     */
    function _claimWithoutTransfer(IERC20 token) internal returns (uint256) {
        FarmRewards storage rewards = farmRewards[token];

        uint256 rewardToClaim = rewards.claimableReward[msg.sender];
        rewards.totalClaimedRewards = rewards.totalClaimedRewards + rewardToClaim;
        rewards.claimableReward[msg.sender] = 0;
        emit Claim(msg.sender, token, rewardToClaim);
        return rewardToClaim;
    }

    /**
     * @dev Internal stake of TRU for stkTRU from a uint256
     * Caller is responsible for ensuring amount is transferred from a valid source
     * @param amount Amount of TRU to stake for stkTRU
     */
    function _stakeWithoutTransfer(uint256 amount) internal {
        require(amount > 0, "StkTruToken: Cannot stake 0");

        if (cooldowns[msg.sender] != 0 && cooldowns[msg.sender] + cooldownTime + unstakePeriodDuration >= block.timestamp) {
            cooldown();
        }

        uint256 amountToMint = stakeSupply == 0 ? amount : (amount * totalSupply) / stakeSupply;
        _mint(msg.sender, amountToMint);
        stakeSupply = stakeSupply + amount;
        emit Stake(msg.sender, amount);
    }

    /**
     * @dev Get reward balance of this contract for a token
     * @param token Token to get reward balance for
     * @return Reward balance for token
     */
    function rewardBalance(IERC20 token) internal view returns (uint256) {
        if (token == tru) {
            return token.balanceOf(address(this)) - stakeSupply;
        }
        if (token == tfusd) {
            return token.balanceOf(address(this)) - undistributedTfusdRewards;
        }
        if (token == feeToken) {
            return token.balanceOf(address(this));
        }
        return 0;
    }

    /**
     * @dev Check if any scheduled rewards should be distributed
     */
    function distributeScheduledRewards() internal {
        uint32 index = nextDistributionIndex;
        uint32 batchLimitIndex = index + SCHEDULED_REWARDS_BATCH_SIZE;
        uint32 end = batchLimitIndex < scheduledRewards.length ? batchLimitIndex : uint32(scheduledRewards.length);
        uint256 _undistributedTfusdRewards = undistributedTfusdRewards;

        while (index < end) {
            ScheduledTfUsdRewards storage rewards = scheduledRewards[sortedScheduledRewardIndices[index]];
            if (rewards.timestamp >= block.timestamp) {
                break;
            }
            _undistributedTfusdRewards = _undistributedTfusdRewards - rewards.amount;
            index++;
        }

        undistributedTfusdRewards = _undistributedTfusdRewards;

        if (nextDistributionIndex != index) {
            nextDistributionIndex = index;
        }
    }

    /**
     * @dev Update rewards state for `token`
     */
    function updateTotalRewards(IERC20 token) internal {
        if (token == tfusd) {
            distributeScheduledRewards();
        }
        FarmRewards storage rewards = farmRewards[token];

        // calculate total rewards
        uint256 newTotalFarmRewards = (rewardBalance(token) + rewards.totalClaimedRewards) * PRECISION;
        if (newTotalFarmRewards == rewards.totalFarmRewards) {
            return;
        }
        // calculate block reward
        uint256 totalBlockReward = newTotalFarmRewards - rewards.totalFarmRewards;
        // update farm rewards
        rewards.totalFarmRewards = newTotalFarmRewards;
        // if there are stakers
        if (totalSupply > 0) {
            rewards.cumulativeRewardPerToken = rewards.cumulativeRewardPerToken + totalBlockReward / totalSupply;
        }
    }

    /**
     * @dev Update claimable rewards for a token and account
     * @param token Token to update claimable rewards for
     * @param user Account to update claimable rewards for
     */
    function updateClaimableRewards(IERC20 token, address user) internal {
        FarmRewards storage rewards = farmRewards[token];

        // update claimable reward for sender
        if (balanceOf[user] > 0) {
            rewards.claimableReward[user] =
                rewards.claimableReward[user] +
                (balanceOf[user] * (rewards.cumulativeRewardPerToken - rewards.previousCumulatedRewardPerToken[user])) /
                PRECISION;
        }

        // update previous cumulative for sender
        rewards.previousCumulatedRewardPerToken[user] = rewards.cumulativeRewardPerToken;
    }

    /**
     * @dev Find next distribution index given a timestamp
     * @param timestamp Timestamp to find next distribution index for
     */
    function findPositionForTimestamp(uint256 timestamp) internal view returns (uint32 i) {
        uint256 length = sortedScheduledRewardIndices.length;
        for (i = nextDistributionIndex; i < length; i++) {
            if (scheduledRewards[sortedScheduledRewardIndices[i]].timestamp > timestamp) {
                return i;
            }
        }
        return i;
    }

    /**
     * @dev internal function to insert distribution index in a sorted list
     * @param index Index to insert at
     * @param value Value at index
     */
    function insertAt(uint32 index, uint32 value) internal {
        sortedScheduledRewardIndices.push(0);
        for (uint32 j = uint32(sortedScheduledRewardIndices.length) - 1; j > index; j--) {
            sortedScheduledRewardIndices[j] = sortedScheduledRewardIndices[j - 1];
        }
        sortedScheduledRewardIndices[index] = value;
    }

    function _writeTotalSupplyCheckpoint(function(uint256, uint256) view returns (uint256) op, uint256 delta)
        internal
        returns (uint256 oldWeight, uint256 newWeight)
    {
        uint256 checkpointsNumber = _totalSupplyCheckpoints.length;
        require(checkpointsNumber > 0, "StakeTruToken: total supply checkpoints not initialized");
        Checkpoint storage lastCheckpoint = _totalSupplyCheckpoints[checkpointsNumber - 1];

        oldWeight = lastCheckpoint.votes;
        newWeight = op(oldWeight, delta);

        if (lastCheckpoint.fromBlock == block.number) {
            lastCheckpoint.votes = SafeCast.toUint96(newWeight);
        } else {
            _totalSupplyCheckpoints.push(
                Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint96(newWeight)})
            );
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage checkpoints, uint256 blockNumber) internal view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = checkpoints.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (checkpoints[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : checkpoints[high - 1].votes;
    }

    function matchVotesToBalance() external onlyOwner {
        address[7] memory accounts = [
            // corrupted voting power
            0xD68C599A549E8518b2E0daB9cD437C930ac2f12B,
            0x4b1A187d7e6D8f2Eb3AC46961DB3468fB824E991,
            // undelegated voting power
            0x57dCb790617D6b8fBe4cDBb3d9b14328A448904f,
            0xF80E102624Eb7A3925Cf807A870FbEf3C760d520,
            0xFe713259F66673076571DfDfbF62F77C138e41A5,
            0x4a88FB2A8A5b7B27ad9E8F7728492485744A1e3f,
            0x4DE8eDFFbDc8eC8b6b8399731D7a9340F90C7663
        ];

        for (uint256 i = 0; i < accounts.length; i++) {
            _matchVotesToBalance(accounts[i]);
        }

        _matchVotesToBalanceAndDelegatorBalance();
    }

    function _matchVotesToBalance(address account) internal {
        uint96 currentVotes = getCurrentVotes(account);
        uint96 balance = safe96(this.balanceOf(account), "StakeTruToken: balance exceeds 96 bits");
        address delegatee = delegates[account];
        if ((delegatee == account || delegatee == address(0)) && currentVotes < balance) {
            _writeCheckpoint(account, numCheckpoints[account], currentVotes, balance);
        }
    }

    function _matchVotesToBalanceAndDelegatorBalance() internal {
        address account = 0xe5D0Ef77AED07C302634dC370537126A2CD26590;
        address delegator = 0xd2c3385f511575851e5bbCd87C59A26Da9Ff71F2;

        uint96 accountBalance = safe96(this.balanceOf(account), "StakeTruToken: balance exceeds 96 bits");
        uint96 delegatorBalance = safe96(this.balanceOf(delegator), "StakeTruToken: balance exceeds 96 bits");

        uint96 currentVotes = getCurrentVotes(account);
        uint96 totalBalance = accountBalance + delegatorBalance;
        if (delegates[account] == address(0) && currentVotes < totalBalance) {
            _writeCheckpoint(account, numCheckpoints[account], currentVotes, totalBalance);
        }
    }
}