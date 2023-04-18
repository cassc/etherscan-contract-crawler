// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./utils/EmergencyState.sol";

interface IPancakePair {
    function balanceOf(address owner) external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

/// @title Farming contract for minted Narfex Token
/// @author Danil Sakhinov
/// @author Vladimir Smelov
/// @notice Distributes a reward from the balance instead of minting it
contract MasterChef is Ownable, ReentrancyGuard, Pausable, EmergencyState {
    using SafeERC20 for IERC20;

    // User share of a pool
    struct UserInfo {
        uint amount; // Amount of LP-tokens deposit
        uint withdrawnReward; // Reward already withdrawn
        uint depositTimestamp; // Last deposit time
        uint harvestTimestamp; // Last harvest time
        uint storedReward; // Reward tokens accumulated in contract (not paid yet)
    }

    struct PoolInfo {
        IERC20 pairToken; // Address of LP token contract
        uint256 allocPoint; // How many allocation points assigned to this pool
        uint256 lastRewardBlock;  // Last block number that NRFX distribution occurs.
        uint256 accRewardPerShare; // Accumulated NRFX per share, times ACC_REWARD_PRECISION=1e12
        uint256 totalDeposited; // Total amount of LP-tokens deposited
        uint256 earlyHarvestCommissionInterval; // The interval from the deposit in which the commission for the reward will be taken.
        uint256 earlyHarvestCommission; // Commission for to early harvests with 2 digits of precision (10000 = 100%)
    }

    uint256 constant internal ACC_REWARD_PRECISION = 1e12;

    /// @notice Reward token to harvest
    IERC20 public immutable rewardToken;

    /// @notice The interval from the deposit in which the commission for the reward will be taken.
    uint256 public earlyHarvestCommissionInterval = 14 days;

    /// @notice Interval since last harvest when next harvest is not possible
    uint256 public harvestInterval = 8 hours;

    /// @notice Commission for to early harvests with 2 digits of precision (10000 = 100%)
    uint256 public earlyHarvestCommission = 1000;  // 1000 = 10%

    /// @notice Referral percent for reward with 2 digits of precision (10000 = 100%)
    uint256 public constant referralPercent = 60;  // 60 = 0.6%

    /// @notice The address of the fee treasury
    address public feeTreasury;

    /// @notice DENOMINATOR for 100% with 2 digits of precision
    uint256 constant public HUNDRED_PERCENTS = 10000;

    /// @notice Info of each pool.
    PoolInfo[] public poolInfo;

    /// @notice Info of each user that stakes LP tokens.
    mapping (uint256 /*poolId*/ => mapping (address => UserInfo)) public userInfo;

    /// @notice Mapping of pools IDs for pair addresses
    mapping (address => uint256) public poolId;

    /// @notice Mapping of users referrals
    mapping (address => address) public referrals;

    /// @notice Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    /// @notice The block number when farming starts
    uint256 public immutable startBlock;
    /// @notice The block number when all allocated rewards will be distributed as rewards
    uint256 public endBlock;

    /// @notice This variable we need to understand how many rewards WAS transferred to the contract since the last call
    uint256 public lastRewardTokenBalance;
    /// @notice restUnallocatedRewards = rewards % rewardPerBlock it's not enough to give new block so we keep it to accumulate with future rewards
    /// @dev these rewards are not accounted in endBlock
    uint256 public restUnallocatedRewards;

    // There are 2 ways how to calculate reward per block:
    //   1) manually set by owner
    //   2) automatically calculated based on the remaining rewards via rewardPerBlockUpdater, see recalculateRewardPerBlock() function

    /// @notice Amount of NRFX per block for all pools
    uint256 public rewardPerBlock;
    /// @notice The address of the reward per block updater
    address public rewardPerBlockUpdater;
    /// @notice The number of blocks generated in the blockchain per day
    uint256 public blockchainBlocksPerDay; // Value is 40,000 on Polygon - https://flipsidecrypto.xyz/niloofar-discord/polygon-block-performance-sMKJcS
    /// @notice The number of days in the estimated reward period, e.g. if set to 100, 1/100 of the remaining rewards will be allocated each day
    uint256 public estimationRewardPeriodDays; // For example, if set to 100, 1/100 of the remaining rewards will be allocated each day

    /// @notice Set the number of blocks generated in the blockchain per day
    /// @param _newBlocksPerDay The new value for the blockchainBlocksPerDay variable
    event BlockchainBlocksPerDayUpdated(uint256 _newBlocksPerDay);

    /// @notice Set the number of days in the expected reward period
    /// @param _newRewardPeriodDays The new value for the estimationRewardPeriodDays variable
    event EstimationRewardPeriodDaysUpdated(uint256 _newRewardPeriodDays);

    /// @notice Set the address of the new reward per block updater
    /// @param _newUpdater The new address for the rewardPerBlockUpdater attribute
    event RewardPerBlockUpdaterUpdated(address indexed _newUpdater);

    /**
     * @notice Event emitted as a result of accounting for new rewards.
     * @param newRewardsAmount The amount of new rewards that were accounted for.
     * @param newEndBlock The block number until which new rewards will be accounted for.
     * @param newRestUnallocatedRewards The remaining unallocated amount of rewards.
     * @param newLastRewardTokenBalance The token balance in the master chef contract after accounting for new rewards.
     * @param afterEndBlock Flag indicating whether the accounting was done after the end of the term.
     */
    event NewRewardsAccounted(
        uint256 newRewardsAmount,
        uint256 newEndBlock,
        uint256 newRestUnallocatedRewards,
        uint256 newLastRewardTokenBalance,
        bool afterEndBlock
    );

    /// @notice Set the address of the new fee treasury
    /// @param _newTreasury The new address for the feeTreasury variable
    event FeeTreasuryUpdated(address indexed _newTreasury);

    /**
     * @notice Event emitted in case no new rewards were accounted for.
     */
    event NoNewRewardsAccounted();

    /**
     * @notice Emitted when the end block is recalculated (because of rewardPerBlock change).
     * @param newEndBlock The new end block number.
     * @param newRestUnallocatedRewards The new value of rest unallocated rewards.
     */
    event EndBlockRecalculatedBecauseOfRewardPerBlockChange(
        uint256 newEndBlock,
        uint256 newRestUnallocatedRewards
    );

    /**
     * @notice Emitted when the end block is recalculated (because of owner withdraw).
     * @param newEndBlock The new end block number.
     * @param newRestUnallocatedRewards The new value of rest unallocated rewards.
     */
    event EndBlockRecalculatedBecauseOfOwnerWithdraw(
        uint256 newEndBlock,
        uint256 newRestUnallocatedRewards
    );

    /**
     * @notice Emitted when the owner withdraws Narfex tokens.
     * @param owner The address of the owner who withdraws the tokens.
     * @param amount The amount of Narfex tokens withdrawn by the owner.
     */
    event WithdrawNarfexByOwner(
        address indexed owner,
        uint256 amount
    );

    /// @notice Emitted when the reward per block is recalculated
    /// @param newRewardPerBlock The new reward per block value
    /// @param futureUnallocatedRewards The future unallocated rewards amount
    /// @param estimationRewardPeriodDays The number of days in the expected reward period
    /// @param blockchainBlocksPerDay The number of blocks generated in the blockchain per day
    /// @param caller The address of the function caller
    event RewardPerBlockRecalculated(
        uint256 newRewardPerBlock,
        uint256 futureUnallocatedRewards,
        uint256 estimationRewardPeriodDays,
        uint256 blockchainBlocksPerDay,
        address indexed caller
    );

    /// @notice Event emitted when a user deposits tokens into a pool
    /// @param user The address of the user who deposited tokens
    /// @param pid The ID of the pool the user deposited tokens into
    /// @param amount The amount of tokens the user deposited
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    /// @notice Event emitted when a user withdraws tokens from a pool
    /// @param user The address of the user who withdrew tokens
    /// @param pid The ID of the pool the user withdrew tokens from
    /// @param amount The amount of tokens the user withdrew
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /// @notice Event emitted when a user harvests rewards from a pool
    /// @param user The address of the user who harvested rewards
    /// @param pid The ID of the pool the user harvested rewards from
    /// @param amount The amount of rewards the user harvested
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);

    /// @notice Event emitted when a user just withdraws tokens from a pool with no rewards
    /// @param user The address of the user who just withdrew tokens
    /// @param pid The ID of the pool the user just withdrew tokens from
    /// @param amount The amount of tokens the user just withdrew
    event JustWithdrawWithNoReward(address indexed user, uint256 indexed pid, uint256 amount);

    /// @notice Event emitted when the total allocation points of all pools are updated
    /// @param totalAllocPoint The new total allocation points
    event TotalAllocPointUpdated(uint256 totalAllocPoint);

    /// @notice Event emitted when a new pool is added to the contract
    /// @param pid The ID of the new pool
    /// @param pairToken The address of the token pair used in the new pool
    /// @param allocPoint The allocation points for the new pool
    event PoolAdded(uint256 indexed pid, address indexed pairToken, uint256 allocPoint);

    /// @notice Event emitted when the allocation points for a pool are updated
    /// @param pid The ID of the pool
    /// @param allocPoint The new allocation points for the pool
    event PoolAllocPointSet(uint256 indexed pid, uint256 allocPoint);

    /// @notice Event emitted when the reward per block is updated
    /// @param rewardPerBlock The new reward per block value
    event RewardPerBlockSet(uint256 rewardPerBlock);

    /// @notice Event emitted when the early harvest commission interval is updated
    /// @param interval The new early harvest commission interval value
    event EarlyHarvestCommissionIntervalSet(uint256 interval);

    /// @notice Event emitted when the early harvest commission is updated
    /// @param percents The new early harvest commission value
    event EarlyHarvestCommissionSet(uint256 percents);

    /// @notice Event emitted when the early harvest commission interval is updated for a pool
    /// @param interval The new early harvest commission interval value
    /// @param pid Pool ID
    event PoolEarlyHarvestCommissionIntervalSet(uint256 interval, uint256 pid);

    /// @notice Event emitted when the early harvest commission is updated for a pool
    /// @param percents The new early harvest commission value
    /// @param pid Pool ID
    event PoolEarlyHarvestCommissionSet(uint256 percents, uint256 pid);

    /// @notice Event emitted when the harvest interval is updated
    /// @param interval The new harvest interval value
    event HarvestIntervalSet(uint256 interval);

    /// @notice Event emitted when a referral reward is paid to a user
    /// @param referral The address of the user who received the referral reward
    /// @param amount The amount of tokens paid as the referral reward
    event ReferralRewardPaid(address indexed referral, uint256 amount);

    /// @notice Event emitted when a referral reward is paid to a treasury
    /// @param treasury The address of the treasury who received the referral reward
    /// @param amount The amount of tokens paid as the referral reward
    event ReferralRewardPaidToTreasury(address indexed treasury, uint256 amount);

    /// @notice Emits an event when the early harvest commission is paid to the fee treasury
    /// @param _feeTreasury The address of the fee treasury receiving the commission
    /// @param _fee The amount of commission paid
    event EarlyHarvestCommissionPaid(address indexed _feeTreasury, uint256 _fee);

    /**
     * @notice This event is emitted when the last reward token balance decreases after a transfer.
     * @dev This event is useful for keeping track of changes in the last reward token balance.
     * @param amount The amount by which the last reward token balance has decreased.
     * @param lastRewardTokenBalance The last value of the balance.
     */
    event LastRewardTokenBalanceDecreasedAfterTransfer(uint256 amount, uint256 lastRewardTokenBalance);

    /**
     * @notice Emitted when tokens or native currency are recovered by the owner
     * @param token The token address that was recovered, or 0x0 for native currency
     * @param to The address that received the recovered tokens or native currency
     * @param amount The amount of tokens or native currency recovered
     */
    event Recovered(address indexed token, address indexed to, uint256 amount);

    /// @notice Constructor for the Narfex MasterChef contract
    /// @param _rewardToken The address of the ERC20 token used for rewards (NRFX)
    /// @param _rewardPerBlock The amount of reward tokens allocated per block
    /// @param _feeTreasury The address of the fee treasury contract
    constructor(
        address _rewardToken,
        uint256 _rewardPerBlock,
        address _feeTreasury
    ) {
        require(_rewardToken != address(0), "zero address");
        rewardToken = IERC20(_rewardToken);
        rewardPerBlock = _rewardPerBlock;
        emit RewardPerBlockSet(rewardPerBlock);
        startBlock = block.number;
        endBlock = block.number;
        require(_feeTreasury != address(0), "zero address");
        feeTreasury = _feeTreasury;
    }

    function pause() external onlyOwner nonReentrant {
        _pause();
    }

    function unpause() external onlyOwner nonReentrant {
        _unpause();
    }

    /// @notice Updates the address of the reward per block updater
    /// @param _newUpdater The new address for the rewardPerBlockUpdater variable
    /// @dev Only the contract owner can call this function
    function setRewardPerBlockUpdater(address _newUpdater) external onlyOwner nonReentrant {
        rewardPerBlockUpdater = _newUpdater;
        emit RewardPerBlockUpdaterUpdated(_newUpdater);
    }

    /// @notice Updates the number of blockchain blocks per day
    /// @param _newBlocksPerDay The new value for the blockchainBlocksPerDay variable
    /// @dev Only the contract owner can call this function
    function setBlockchainBlocksPerDay(uint256 _newBlocksPerDay) external onlyOwner nonReentrant {
        blockchainBlocksPerDay = _newBlocksPerDay;
        emit BlockchainBlocksPerDayUpdated(_newBlocksPerDay);
    }

    /// @notice Updates the number of estimation reward period days
    /// @param _newRewardPeriodDays The new value for the estimationRewardPeriodDays variable
    /// @dev Only the contract owner can call this function
    function setEstimationRewardPeriodDays(uint256 _newRewardPeriodDays) external onlyOwner nonReentrant {
        estimationRewardPeriodDays = _newRewardPeriodDays;
        emit EstimationRewardPeriodDaysUpdated(_newRewardPeriodDays);
    }

    /// @notice Updates the address of the fee treasury
    /// @param _newTreasury The new address for the feeTreasury variable
    /// @dev Only the contract owner can call this function
    function setFeeTreasury(address _newTreasury) external onlyOwner nonReentrant {
        require(_newTreasury != address(0), "Invalid address provided.");
        feeTreasury = _newTreasury;
        emit FeeTreasuryUpdated(_newTreasury);
    }

    /// @notice Recalculates the reward per block based on the unallocated rewards and estimation reward period days
    /// @dev This function can be called by either the contract owner or rewardPerBlockUpdater
    function recalculateRewardPerBlock() external nonReentrant {
        require(msg.sender == owner() || msg.sender == rewardPerBlockUpdater, "no access");
        require(estimationRewardPeriodDays != 0, "estimationRewardPeriodDays is zero");
        require(blockchainBlocksPerDay != 0, "blockchainBlocksPerDay is zero");

        _accountNewRewards();
        _massUpdatePools();

        uint256 _futureUnallocatedRewards = futureUnallocatedRewards();
        uint256 newRewardPerBlock = _futureUnallocatedRewards / (estimationRewardPeriodDays * blockchainBlocksPerDay);

        emit RewardPerBlockRecalculated({
            newRewardPerBlock: newRewardPerBlock,
            futureUnallocatedRewards: _futureUnallocatedRewards,
            estimationRewardPeriodDays: estimationRewardPeriodDays,
            blockchainBlocksPerDay: blockchainBlocksPerDay,
            caller: msg.sender
        });
        _setRewardPerBlock(newRewardPerBlock);
    }

    /**
     * @notice Account new rewards from the reward pool. This function can be called periodically by anyone to distribute new rewards to the reward pool.
     */
    function accountNewRewards() external nonReentrant {
        _accountNewRewards();
    }

    function _accountNewRewards() internal {
        uint256 currentBalance = getNarfexBalance();
        uint256 newRewardsAmount = currentBalance - lastRewardTokenBalance;
        if (newRewardsAmount == 0) {
            emit NoNewRewardsAccounted();
            return;
        }
        uint256 _rewardPerBlockWithReferralPercent = rewardPerBlockWithReferralPercent();
        lastRewardTokenBalance = currentBalance;  // account new balance
        uint256 newRewardsToAccount = newRewardsAmount + restUnallocatedRewards;
        if ((block.number > endBlock) && (startBlock != endBlock)) {
            if (newRewardsToAccount > _rewardPerBlockWithReferralPercent) {
                // if there are more rewards than the reward per block, then we need to extend the end block

                _massUpdatePools();  // set all poolInfo.lastRewardBlock=block.number

                uint256 deltaBlocks = newRewardsToAccount / _rewardPerBlockWithReferralPercent;
                endBlock = block.number + deltaBlocks;  // start give rewards AGAIN from block.number
                restUnallocatedRewards = newRewardsToAccount - deltaBlocks * _rewardPerBlockWithReferralPercent;  // (newRewardsAmount + restUnallocatedRewards) % rewardPerBlockWithReferralPercent
                emit NewRewardsAccounted({
                    newRewardsAmount: newRewardsAmount,
                    newEndBlock: endBlock,
                    newRestUnallocatedRewards: restUnallocatedRewards,
                    newLastRewardTokenBalance: lastRewardTokenBalance,
                    afterEndBlock: true
                });

                return;
            }

            // accumulate rewards in `restUnallocatedRewards` after the end block
            // note that if startBlock == endBlock it will make initial endBlock setting
            restUnallocatedRewards = newRewardsToAccount;
            emit NewRewardsAccounted({
                newRewardsAmount: newRewardsAmount,
                newEndBlock: endBlock,
                newRestUnallocatedRewards: restUnallocatedRewards,
                newLastRewardTokenBalance: lastRewardTokenBalance,
                afterEndBlock: true
            });
            return;
        }
        uint256 _deltaBlocks = newRewardsToAccount / _rewardPerBlockWithReferralPercent;
        endBlock += _deltaBlocks;
        restUnallocatedRewards = newRewardsToAccount - _deltaBlocks * _rewardPerBlockWithReferralPercent;  // (newRewardsAmount + restUnallocatedRewards) % rewardPerBlockWithReferralPercent
        emit NewRewardsAccounted({
            newRewardsAmount: newRewardsAmount,
            newEndBlock: endBlock,
            newRestUnallocatedRewards: restUnallocatedRewards,
            newLastRewardTokenBalance: lastRewardTokenBalance,
            afterEndBlock: false
        });
    }

    /// @notice Calculates the reward per block with referral percentage included
    /// @dev Calculates the reward per block with referral percentage included by multiplying the reward per block by 100% + referral percent
    /// @return The reward per block with referral percentage included
    function rewardPerBlockWithReferralPercent() public view returns(uint256) {
        return rewardPerBlock * (HUNDRED_PERCENTS + referralPercent) / HUNDRED_PERCENTS;
    }

    /// @notice Count of created pools
    /// @return poolInfo length
    function getPoolsCount() external view returns (uint256) {
        return poolInfo.length;
    }

    /// @notice Returns the balance of reward token in the contract
    /// @return Reward left in the common pool
    function getNarfexBalance() public view returns (uint) {
        return rewardToken.balanceOf(address(this));
    }

    /// @notice Calculate the estimated unallocated rewards for the remaining blocks
    /// @return The estimated unallocated rewards for the remaining blocks
    function futureUnallocatedRewards() public view returns(uint256) {
        if (block.number >= endBlock) {
            return restUnallocatedRewards;
        } else {
            uint256 futureBlocks = endBlock - block.number;
            uint256 _rewardPerBlockWithReferralPercent = rewardPerBlockWithReferralPercent();
            return _rewardPerBlockWithReferralPercent * futureBlocks + restUnallocatedRewards;
        }
    }

    /// @notice Calculate the estimated end block and remaining rewards based on the provided reward allocation
    /// @param _rewards The total unallocated rewards to be distributed
    /// @param _rewardPerBlock The reward allocation per block
    /// @return _endBlock The estimated end block
    /// @return _rest The estimated remaining rewards
    function calculateFutureRewardAllocationWithArgs(
        uint256 _rewards,
        uint256 _rewardPerBlock
    ) public view returns(
        uint256 _endBlock,
        uint256 _rest
    ) {
        // Calculate the number of blocks needed to allocate the remaining rewards
        uint256 blocks = _rewards / _rewardPerBlock;

        // Calculate the estimated end block based on the current block number and the number of blocks needed
        _endBlock = block.number + blocks;

        // Calculate the remaining rewards after all full blocks have been allocated
        _rest = _rewards - blocks * _rewardPerBlock;
    }

    /**
     * @notice Withdraws an amount of reward tokens to the owner of the contract. Only unallocated reward tokens can be withdrawn.
     * @param amount The amount of reward tokens to withdraw
     * @dev Only the contract owner can call this function
     */
    function withdrawNarfexByOwner(uint256 amount) external onlyOwner nonReentrant {
        // Validate the withdrawal amount
        require(amount > 0, "zero amount");
        require(amount <= getNarfexBalance(), "Not enough reward tokens left");

        _accountNewRewards();

        // Calculate the remaining rewards
        uint256 _futureUnallocatedRewards = futureUnallocatedRewards();
        require(amount <= _futureUnallocatedRewards, "not enough unallocated rewards");
        
        // Calculate the new unallocated rewards after the withdrawal
        uint256 newUnallocatedRewards = _futureUnallocatedRewards - amount;
        
        // Update the end block and remaining unallocated rewards
        (endBlock, restUnallocatedRewards) = calculateFutureRewardAllocationWithArgs(newUnallocatedRewards, rewardPerBlockWithReferralPercent());
        
        // Emit events for the updated end block and withdrawn amount
        emit EndBlockRecalculatedBecauseOfOwnerWithdraw(endBlock, restUnallocatedRewards);
        emit WithdrawNarfexByOwner(msg.sender, amount);
        
        // Transfer the withdrawn amount to the contract owner's address
        _transferNRFX(msg.sender, amount);
    }

    /**
     * @notice Modifier that checks if the pool corresponding to a given pair address exists
     * @param _pairAddress The address of the pool's pair token
     */
    modifier onlyExistPool(address _pairAddress) {
        require(poolExists(_pairAddress), "pool not exist");
        _;
    }

     /**
      * @notice Checks if the pool corresponding to a given pair address exists
      * @param _pairAddress The address of the pool's pair token
      * @return True if the pool exists, false otherwise
      */
    function poolExists(address _pairAddress) public view returns(bool) {
        uint256 _poolId = poolId[_pairAddress];
        if (_poolId == 0) {
            if (poolInfo.length == 0) {
                return false;
            } else {
                return address(poolInfo[0].pairToken) == _pairAddress;
            }
        } else {
            return true;
        }
    }

    /// @notice Add a new pool
    /// @param _allocPoint Allocation point for this pool
    /// @param _pairAddress Address of LP token contract
    function add(uint256 _allocPoint, address _pairAddress) external onlyOwner nonReentrant {
        require(!poolExists(_pairAddress), "already exists");
        _massUpdatePools();
        uint256 lastRewardBlock = Math.max(block.number, startBlock);
        totalAllocPoint = totalAllocPoint + _allocPoint;
        emit TotalAllocPointUpdated(totalAllocPoint);
        poolInfo.push(PoolInfo({
            pairToken: IERC20(_pairAddress),
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accRewardPerShare: 0,
            totalDeposited: 0,
            earlyHarvestCommissionInterval: earlyHarvestCommissionInterval,
            earlyHarvestCommission: earlyHarvestCommission
        }));
        poolId[_pairAddress] = poolInfo.length - 1;
        emit PoolAdded({
            pid: poolId[_pairAddress],
            pairToken: _pairAddress,
            allocPoint: _allocPoint
        });
    }

    /// @notice Update allocation points for a pool
    /// @param _pid Pool index
    /// @param _allocPoint Allocation points
    function set(uint256 _pid, uint256 _allocPoint) external onlyOwner nonReentrant {
        _massUpdatePools();
        totalAllocPoint = totalAllocPoint + _allocPoint - poolInfo[_pid].allocPoint;
        emit TotalAllocPointUpdated(totalAllocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;  // note: revert if not exist
        emit PoolAllocPointSet({
            pid: _pid,
            allocPoint: _allocPoint
        });
    }

    /// @notice Set a new reward per block amount (runs _massUpdatePools)
    /// @param _amount Amount of reward tokens per block
    function setRewardPerBlock(uint256 _amount) external onlyOwner nonReentrant {
        _setRewardPerBlock(_amount);
    }

    /// @dev Set a new reward per block amount
    function _setRewardPerBlock(uint256 newRewardPerBlock) internal {
        _accountNewRewards();
        _massUpdatePools();  // set poolInfo.lastRewardBlock=block.number

        uint256 futureRewards = futureUnallocatedRewards();
        rewardPerBlock = newRewardPerBlock;
        emit RewardPerBlockSet(newRewardPerBlock);

        // endBlock = currentBlock + unallocatedRewards / rewardPerBlock
        // so now we should update the endBlock since rewardPerBlock was changed
        uint256 _rewardPerBlockWithReferralPercent = rewardPerBlockWithReferralPercent();
        uint256 deltaBlocks = futureRewards / _rewardPerBlockWithReferralPercent;
        endBlock = block.number + deltaBlocks;
        restUnallocatedRewards = futureRewards - deltaBlocks * _rewardPerBlockWithReferralPercent;
        emit EndBlockRecalculatedBecauseOfRewardPerBlockChange({
            newEndBlock: endBlock,
            newRestUnallocatedRewards: restUnallocatedRewards
        });
    }

    /// @notice Calculates the reward for a user based on their staked amount, accumulated reward per share, and withdrawn and stored rewards.
    /// @param user UserInfo storage of the user for whom to calculate the reward
    /// @param _accRewardPerShare Accumulated reward per share, calculated as (total reward / total staked amount)
    /// @return The reward amount for the user based on their staked amount and the accumulated reward per share, minus the withdrawn rewards, and plus the stored rewards.
    function _calculateUserReward(
        UserInfo storage user,
        uint256 _accRewardPerShare
    ) internal view returns (uint256) {
        return user.amount * _accRewardPerShare / ACC_REWARD_PRECISION - user.withdrawnReward + user.storedReward;
    }

    /// @notice Calculates the user's reward based on a blocks range
    /// @param _pairAddress The address of LP token
    /// @param _user The user address
    /// @return reward size
    /// @dev Only for frontend view
    function getUserReward(address _pairAddress, address _user) public view onlyExistPool(_pairAddress) returns (uint256) {
        uint256 _pid = poolId[_pairAddress];
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.totalDeposited;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 rightBlock = Math.min(block.number, endBlock);
            uint256 leftBlock = Math.max(pool.lastRewardBlock, startBlock);
            if (rightBlock > leftBlock) {
                uint256 blocks = rightBlock - leftBlock;
                uint256 reward = blocks * rewardPerBlock * pool.allocPoint / totalAllocPoint;
                accRewardPerShare += reward * ACC_REWARD_PRECISION / lpSupply;
            }
        }
        return _calculateUserReward(user, accRewardPerShare);
    }

    /// @notice If enough time has passed since the last harvest
    /// @param _pairAddress The address of LP token
    /// @param _user The user address
    /// @return true if user can harvest
    function getIsUserCanHarvest(address _pairAddress, address _user) public view onlyExistPool(_pairAddress) returns (bool) {
        uint256 _pid = poolId[_pairAddress];
        UserInfo storage user = userInfo[_pid][_user];
        bool isEarlyHarvest = block.timestamp - user.harvestTimestamp < harvestInterval;
        return !isEarlyHarvest;
    }

    /// @notice Returns user's amount of LP tokens
    /// @param _pairAddress The address of LP token
    /// @param _user The user address
    /// @return user's pool size
    function getUserPoolSize(address _pairAddress, address _user) external view onlyExistPool(_pairAddress) returns (uint) {
        uint256 _pid = poolId[_pairAddress];
        return userInfo[_pid][_user].amount;
    }

    /// @notice Returns contract settings by one request
    /// @return uintRewardPerBlock uintRewardPerBlock
    /// @return uintEarlyHarvestCommissionInterval uintEarlyHarvestCommissionInterval
    /// @return uintHarvestInterval uintHarvestInterval
    /// @return uintEarlyHarvestCommission uintEarlyHarvestCommission
    /// @return uintReferralPercent uintReferralPercent
    function getSettings() public view returns (
        uint uintRewardPerBlock,
        uint uintEarlyHarvestCommissionInterval,
        uint uintHarvestInterval,
        uint uintEarlyHarvestCommission,
        uint uintReferralPercent
    ) {
        return (
            rewardPerBlock,
            earlyHarvestCommissionInterval,
            harvestInterval,
            earlyHarvestCommission,
            referralPercent
        );
    }

    /// @notice Get pool data in one request
    /// @param _pairAddress The address of LP token
    /// @return token0 First token address
    /// @return token1 Second token address
    /// @return token0symbol First token symbol
    /// @return token1symbol Second token symbol
    /// @return totalDeposited Total amount of LP tokens deposited
    /// @return poolShare Share of the pool based on allocation points
    function getPoolData(address _pairAddress) public view onlyExistPool(_pairAddress) returns (
        address token0,
        address token1,
        string memory token0symbol,
        string memory token1symbol,
        uint totalDeposited,
        uint poolShare
    ) {
        uint256 _pid = poolId[_pairAddress];
        IPancakePair pairToken = IPancakePair(_pairAddress);
        IERC20Metadata _token0 = IERC20Metadata(pairToken.token0());
        IERC20Metadata _token1 = IERC20Metadata(pairToken.token1());

        return (
            pairToken.token0(),
            pairToken.token1(),
            _token0.symbol(),
            _token1.symbol(),
            poolInfo[_pid].totalDeposited,
            poolInfo[_pid].allocPoint * HUNDRED_PERCENTS / totalAllocPoint
        );
    }

    /// @notice Returns pool data in one request
    /// @param _pairAddress The ID of liquidity pool
    /// @param _user The user address
    /// @return balance User balance of LP token
    /// @return userPool User liquidity pool size in the current pool
    /// @return reward Current user reward in the current pool
    /// @return isCanHarvest Is it time to harvest the reward
    function getPoolUserData(address _pairAddress, address _user) public view onlyExistPool(_pairAddress) returns (
        uint balance,
        uint userPool,
        uint256 reward,
        bool isCanHarvest
    ) {
        return (
            IPancakePair(_pairAddress).balanceOf(_user),
            userInfo[poolId[_pairAddress]][_user].amount,
            getUserReward(_pairAddress, _user),
            getIsUserCanHarvest(_pairAddress, _user)
        );
    }

    /// @notice Sets the early harvest commission interval
    /// @param interval Interval size in seconds
    function setEarlyHarvestCommissionInterval(uint interval) external onlyOwner nonReentrant {
        earlyHarvestCommissionInterval = interval;
        emit EarlyHarvestCommissionIntervalSet(interval);
    }

    /// @notice Sets the early harvest commission interval for a pool
    /// @param interval Interval size in seconds
    /// @param _pid Pool ID
    function setEarlyHarvestCommissionInterval(uint interval, uint _pid) external onlyOwner nonReentrant {
        poolInfo[_pid].earlyHarvestCommissionInterval = interval;
        emit PoolEarlyHarvestCommissionIntervalSet(interval, _pid);
    }

    /// @notice Sets the harvest interval
    /// @param interval Interval size in seconds
    function setHarvestInterval(uint interval) external onlyOwner nonReentrant {
        harvestInterval = interval;
        emit HarvestIntervalSet(interval);
    }

    /// @notice Sets the early harvest commission
    /// @param percents Early harvest commission in percents denominated by 10000 (1000 for default 10%)
    function setEarlyHarvestCommission(uint percents) external onlyOwner nonReentrant {
        earlyHarvestCommission = percents;
        emit EarlyHarvestCommissionSet(percents);
    }

    /// @notice Sets the early harvest commission for a pool
    /// @param percents Early harvest commission in percents denominated by 10000 (1000 for default 10%)
    /// @param _pid Pool ID
    function setEarlyHarvestCommission(uint percents, uint _pid) external onlyOwner nonReentrant {
        poolInfo[_pid].earlyHarvestCommission = percents;
        emit PoolEarlyHarvestCommissionSet(percents, _pid);
    }

    /**
     * @notice Updates all pools and rewards the users with the new rewards
     * @dev Calls the internal function _massUpdatePools
     * @dev This function should be called before any deposit, withdrawal, or harvest operation
     * @dev Only one call to this function can be made at a time
     */
    function massUpdatePools() external nonReentrant {
        _accountNewRewards();
        _massUpdatePools();
    }

    /**
     * @dev Internal function that updates all pools
     */
    function _massUpdatePools() internal {
        uint256 length = poolInfo.length;
        unchecked {
            for (uint256 pid = 0; pid < length; ++pid) {
                _updatePool(pid);
            }
        }
    }

    /// @notice Update reward variables of the given pool to be up-to-date
    /// @param _pid Pool index
    function updatePool(uint256 _pid) external nonReentrant {
        _accountNewRewards();
        _updatePool(_pid);
    }

    function _updatePool(uint256 _pid) internal {  // todo tricky enable disable
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.totalDeposited;
        if (lpSupply == 0) {
            // WARNING: always keep some small deposit in every pool
            // there could be a small problem if no one will deposit in the pool with e.g. 30% allocation point
            // then the reward for this 30% alloc points will never be distributed
            // however endBlock is already set, so no one will harvest the.
            // But fixing this problem with math would increase complexity of the code.
            // So just let the owner to keep 1 lp token in every pool to mitigate this problem.
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 rightBlock = Math.min(block.number, endBlock);
        uint256 leftBlock = Math.max(pool.lastRewardBlock, startBlock);
        if (rightBlock <= leftBlock) {
           pool.lastRewardBlock = block.number;
           return;  // after endBlock passed we continue to scroll lastRewardBlock with no update of accRewardPerShare
        }
        uint256 blocks = rightBlock - leftBlock;
        uint256 reward = blocks * rewardPerBlock * pool.allocPoint / totalAllocPoint;
        pool.accRewardPerShare += reward * ACC_REWARD_PRECISION / lpSupply;
        pool.lastRewardBlock = block.number;
    }

    /// @dev some erc20 may have internal transferFee or deflationary mechanism so the actual received amount after transfer will not match the transfer amount
    function _safeTransferFromCheckingBalance(IERC20 token, address from, address to, uint256 amount) internal {
        uint256 balanceBefore = token.balanceOf(to);
        token.safeTransferFrom(from, to, amount);
        require(token.balanceOf(to) - balanceBefore == amount, "transfer amount mismatch");
    }

    /// @notice Deposit LP tokens to the farm. It will try to harvest first
    /// @param _pairAddress The address of LP token
    /// @param _amount Amount of LP tokens to deposit
    /// @param _referral Address of the agent who invited the user
    function deposit(address _pairAddress, uint256 _amount, address _referral) public onlyExistPool(_pairAddress) nonReentrant whenNotPaused notEmergency {
        _accountNewRewards();
        uint256 _pid = poolId[_pairAddress];
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        _updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = _calculateUserReward(user, pool.accRewardPerShare);
            if (pending > 0) {
                _rewardTransfer({user: user, _amount: pending, isWithdraw: false, _pid: _pid});
            }
        }
        if (_amount > 0) {
            _safeTransferFromCheckingBalance(IERC20(pool.pairToken), msg.sender, address(this), _amount);
            user.amount += _amount;
            pool.totalDeposited += _amount;
        }
        user.withdrawnReward = user.amount * pool.accRewardPerShare / ACC_REWARD_PRECISION;
        user.depositTimestamp = block.timestamp;
        emit Deposit(msg.sender, _pid, _amount);
        if (_referral != address(0) && _referral != msg.sender && referrals[msg.sender] != _referral) {
            referrals[msg.sender] = _referral;
        }
    }

    /**
     * @notice Deposit tokens into a pool without referral
     * @param _pairAddress Address of the pair token to deposit into
     * @param _amount Amount of tokens to deposit
     */
    function depositWithoutRefer(address _pairAddress, uint256 _amount) public {
        deposit(_pairAddress, _amount, address(0));
    }

    /// @notice Withdraw LP tokens from the farm. It will try to harvest first
    /// @param _pairAddress The address of LP token
    /// @param _amount Amount of LP tokens to withdraw
    function withdraw(address _pairAddress, uint256 _amount) public nonReentrant onlyExistPool(_pairAddress) whenNotPaused notEmergency {
        _accountNewRewards();
        uint256 _pid = poolId[_pairAddress];
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        _updatePool(_pid);

        require(user.amount >= _amount, "Too big amount");
        _harvest(_pairAddress);
        if (_amount > 0) {
            user.amount -= _amount;
            pool.totalDeposited -= _amount;
            pool.pairToken.safeTransfer(address(msg.sender), _amount);
        }
        user.withdrawnReward = user.amount * pool.accRewardPerShare / ACC_REWARD_PRECISION;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Returns LP tokens to the user with the entire reward reset to zero
    /// @param _pairAddress The address of LP token
    function justWithdrawWithNoReward(address _pairAddress) public nonReentrant onlyExistPool(_pairAddress) {
        uint256 _pid = poolId[_pairAddress];
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.withdrawnReward = 0;
        user.storedReward = 0;
        pool.pairToken.safeTransfer(address(msg.sender), amount);
        emit JustWithdrawWithNoReward(msg.sender, _pid, amount);
    }

    /// @notice Harvest rewards for the given pool and transfer them to the user's address.
    /// @param _pairAddress The address of the pool contract.
    function _harvest(address _pairAddress) internal {
        uint256 _pid = poolId[_pairAddress];
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        _updatePool(_pid);
        uint256 pending = _calculateUserReward(user, pool.accRewardPerShare);
        if (pending > 0) {
            _rewardTransfer({user: user, _amount: pending, isWithdraw: true, _pid: _pid});
        }
        user.withdrawnReward = user.amount * pool.accRewardPerShare / ACC_REWARD_PRECISION;
    }
    
    /// @notice Harvest reward from the pool and send to the user
    /// @param _pairAddress The address of LP token
    function harvest(address _pairAddress) public onlyExistPool(_pairAddress) whenNotPaused notEmergency nonReentrant {
        _harvest(_pairAddress);
    }

    /// @notice Recover any token accidentally sent to the contract (does not allow recover deposited LP and reward tokens)
    /// @param token Token to recover
    /// @param to Where to send recovered tokens
    /// @param amount Amount to send
    function recoverERC20(address token, address to, uint256 amount) external onlyOwner nonReentrant {
        require(token != address(rewardToken), "cannot recover reward token");
        if (poolExists(token)) {
            PoolInfo storage pool = poolInfo[poolId[token]];
            uint256 rest = IERC20(token).balanceOf(address(this)) - pool.totalDeposited;
            require(amount <= rest, "cannot withdraw deposited amount");
            IERC20(token).safeTransfer(to, amount);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
        emit Recovered(address(token), to, amount);
    }

    /// @notice Recover reward token in case of emergency
    /// @param to Where to send recovered tokens
    /// @param amount Amount to send
    function emergencyRecoverReward(address to, uint256 amount) external onlyOwner nonReentrant onlyEmergency {
        IERC20(rewardToken).safeTransfer(to, amount);
        emit Recovered(address(rewardToken), to, amount);
    }

    /// @notice Transfer reward with all checks
    /// @param user UserInfo storage pointer
    /// @param _amount Amount of reward to transfer
    /// @param isWithdraw Set to false if it called by deposit function
    /// @param _pid Pool index
    function _rewardTransfer(
        UserInfo storage user,
        uint256 _amount,
        bool isWithdraw,
        uint256 _pid
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        bool isEarlyHarvestCommission = block.timestamp - user.depositTimestamp < pool.earlyHarvestCommissionInterval;
        bool isEarlyHarvest = block.timestamp - user.harvestTimestamp < harvestInterval;
        
        if (isEarlyHarvest) {
            user.storedReward = _amount;
            return;
        }

        uint amountToUser = _amount;
        if (isWithdraw && isEarlyHarvestCommission) {
            uint256 fee = pool.earlyHarvestCommission / HUNDRED_PERCENTS;
            amountToUser = _amount - fee;
            _transferNRFX(feeTreasury, fee);
            emit EarlyHarvestCommissionPaid(feeTreasury, fee);
        }

        uint256 harvestedAmount = _transferNRFX(msg.sender, amountToUser);
        emit Harvest(msg.sender, _pid, harvestedAmount);

        // Send referral reward
        address referral = referrals[msg.sender];
        uint256 referralAmount = _amount * referralPercent / HUNDRED_PERCENTS;  // note: initial _amount not amountToUser
        if (referral != address(0)) {
            uint256 referralRewardPaid = _transferNRFX(referral, referralAmount);
            emit ReferralRewardPaid(referral, referralRewardPaid);
        } else {
            uint256 referralRewardPaid = _transferNRFX(feeTreasury, referralAmount);
            emit ReferralRewardPaidToTreasury(feeTreasury, referralRewardPaid);
        }

        user.storedReward = 0;
        user.harvestTimestamp = block.timestamp;
    }

    /**
     * @notice Transfer a specified amount of NRFX tokens to a specified address, after ensuring that there are sufficient
     *         NRFX tokens remaining in the contract. If the remaining NRFX tokens are less than the specified amount,
     *         then transfer the remaining amount of NRFX tokens. If the transferred amount is greater than zero.
     *         This function is intended to be used for transferring NRFX tokens for referral rewards.
     * @param to The address to which the NRFX tokens are transferred
     * @param amount The amount of NRFX tokens to transfer
     * @return The amount of NRFX tokens that were actually transferred
     */
    function _transferNRFX(address to, uint256 amount) internal returns(uint256) {
        // Get the remaining NRFX tokens
        uint256 narfexLeft = getNarfexBalance();

        // If the remaining NRFX tokens are less than the specified amount, transfer the remaining amount of NRFX tokens
        if (narfexLeft < amount) {
            amount = narfexLeft;
        }
        if (amount > 0) {
            rewardToken.safeTransfer(to, amount);
            lastRewardTokenBalance -= amount;
            emit LastRewardTokenBalanceDecreasedAfterTransfer(amount, lastRewardTokenBalance);
        }
        return amount;
    }
}