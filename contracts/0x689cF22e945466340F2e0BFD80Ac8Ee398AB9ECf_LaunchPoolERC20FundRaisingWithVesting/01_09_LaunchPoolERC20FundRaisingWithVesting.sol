// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import { FundRaisingGuild } from "./FundRaisingGuild.sol";

/// @title Fund raising platform facilitated by launch pool
/// @author BlockRocket.tech
/// @notice Fork of MasterChef.sol from SushiSwap
/// @dev Only the owner can add new pools
contract LaunchPoolERC20FundRaisingWithVesting is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Details about each user in a pool
    struct UserInfo {
        uint256 amount;     // How many tokens are staked in a pool
        uint256 pledgeFundingAmount; // Based on staked tokens, the funding that has come from the user (or not if they choose to pull out)
        uint256 rewardDebtRewards; // Reward debt. See explanation below.
        uint256 tokenAllocDebt;
        //
        // We do some fancy math here. Basically, once vesting has started in a pool (if they have deposited), the amount of reward tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebtRewards
        //
        // The amount can never change once the staking period has ended
    }

    /// @dev Info of each pool.
    struct PoolInfo {
        IERC20 rewardToken; // Address of the reward token contract.
        IERC20 fundRaisingToken; // Address of the fund raising token contract.
        uint256 tokenAllocationStartBlock; // Block when users stake counts towards earning reward token allocation
        uint256 stakingEndBlock; // Before this block, staking is permitted
        uint256 pledgeFundingEndBlock; // Between stakingEndBlock and this number pledge funding is permitted
        uint256 targetRaise; // Amount that the project wishes to raise
        uint256 maxStakingAmountPerUser; // Max. amount of tokens that can be staked per account/user
    }

    /// @notice staking token is fixed for all pools
    IERC20 public stakingToken;

    /// @notice Container for holding all rewards
    FundRaisingGuild public rewardGuildBank;

    /// @notice List of pools that users can stake into
    PoolInfo[] public poolInfo;

    // Pool to accumulated share counters
    mapping(uint256 => uint256) public poolIdToAccPercentagePerShare;
    mapping(uint256 => uint256) public poolIdToLastPercentageAllocBlock;

    // Number of reward tokens distributed per block for this pool
    mapping(uint256 => uint256) public poolIdToRewardPerBlock;

    // Last block number that reward token distribution took place
    mapping(uint256 => uint256) public poolIdToLastRewardBlock;

    // Block number when rewards start
    mapping(uint256 => uint256) public poolIdToRewardStartBlock;

    // Block number when cliff ends
    mapping(uint256 => uint256) public poolIdToRewardCliffEndBlock;

    // Block number when rewards end
    mapping(uint256 => uint256) public poolIdToRewardEndBlock;

    // Per LPOOL token staked, how much reward token earned in pool that users will get
    mapping(uint256 => uint256) public poolIdToAccRewardPerShareVesting;

    // Total rewards being distributed up to rewardEndBlock
    mapping(uint256 => uint256) public poolIdToMaxRewardTokensAvailableForVesting;

    // Total amount staked into the pool
    mapping(uint256 => uint256) public poolIdToTotalStaked;

    // Total amount of funding received by stakers after stakingEndBlock and before pledgeFundingEndBlock
    mapping(uint256 => uint256) public poolIdToTotalRaised;

    // For every staker that funded their pledge, the sum of all of their allocated percentages
    mapping(uint256 => uint256) public poolIdToTotalFundedPercentageOfTargetRaise;

    // True when funds have been claimed
    mapping(uint256 => bool) public poolIdToFundsClaimed;

    /// @notice Per pool, info of each user that stakes ERC20 tokens.
    /// @notice Pool ID => User Address => User Info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Available before staking ends for any given project. Essentitally 100% to 18 dp
    uint256 public constant TOTAL_TOKEN_ALLOCATION_POINTS = (100 * (10 ** 18));

    event ContractDeployed(address indexed guildBank);
    event PoolAdded(uint256 indexed pid);
    event Pledge(address indexed user, uint256 indexed pid, uint256 amount);
    event PledgeFunded(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardsSetUp(uint256 indexed pid, uint256 amount, uint256 rewardEndBlock);
    event RewardClaimed(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event FundRaisingClaimed(uint256 indexed pid, address indexed recipient, uint256 amount);

    /// @param _stakingToken Address of the staking token for all pools
    constructor(IERC20 _stakingToken) public {
        require(address(_stakingToken) != address(0), "constructor: _stakingToken must not be zero address");

        stakingToken = _stakingToken;
        rewardGuildBank = new FundRaisingGuild(address(this));

        emit ContractDeployed(address(rewardGuildBank));
    }

    /// @notice Returns the number of pools that have been added by the owner
    /// @return Number of pools
    function numberOfPools() external view returns (uint256) {
        return poolInfo.length;
    }

    /// @dev Can only be called by the contract owner
    function add(
        IERC20 _rewardToken,
        IERC20 _fundRaisingToken,
        uint256 _tokenAllocationStartBlock,
        uint256 _stakingEndBlock,
        uint256 _pledgeFundingEndBlock,
        uint256 _targetRaise,
        uint256 _maxStakingAmountPerUser,
        bool _withUpdate
    ) public onlyOwner {
        address rewardTokenAddress = address(_rewardToken);
        require(rewardTokenAddress != address(0), "add: _rewardToken is zero address");
        address fundRaisingTokenAddress = address(_fundRaisingToken);
        require(fundRaisingTokenAddress != address(0), "add: _fundRaisingToken is zero address");
        require(_tokenAllocationStartBlock < _stakingEndBlock, "add: _tokenAllocationStartBlock must be before staking end");
        require(_stakingEndBlock < _pledgeFundingEndBlock, "add: staking end must be before funding end");
        require(_targetRaise > 0, "add: Invalid raise amount");

        if (_withUpdate) {
            massUpdatePools();
        }

        poolInfo.push(PoolInfo({
            rewardToken : _rewardToken,
            fundRaisingToken : _fundRaisingToken,
            tokenAllocationStartBlock: _tokenAllocationStartBlock,
            stakingEndBlock: _stakingEndBlock,
            pledgeFundingEndBlock: _pledgeFundingEndBlock,
            targetRaise: _targetRaise,
            maxStakingAmountPerUser: _maxStakingAmountPerUser
        }));

        poolIdToLastPercentageAllocBlock[poolInfo.length.sub(1)] = _tokenAllocationStartBlock;

        emit PoolAdded(poolInfo.length.sub(1));
    }

    // step 1
    function pledge(uint256 _pid, uint256 _amount) external nonReentrant {
        require(_pid < poolInfo.length, "pledge: Invalid PID");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(_amount > 0, "pledge: No pledge specified");
        require(block.number <= pool.stakingEndBlock, "pledge: Staking no longer permitted");

        require(user.amount.add(_amount) <= pool.maxStakingAmountPerUser, "pledge: can not exceed max staking amount per user");

        updatePool(_pid);

        user.amount = user.amount.add(_amount);
        user.tokenAllocDebt = user.tokenAllocDebt.add(_amount.mul(poolIdToAccPercentagePerShare[_pid]).div(1e18));

        poolIdToTotalStaked[_pid] = poolIdToTotalStaked[_pid].add(_amount);

        stakingToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        emit Pledge(msg.sender, _pid, _amount);
    }

    function getPledgeFundingAmount(uint256 _pid) public view returns (uint256) {
        require(_pid < poolInfo.length, "getPledgeFundingAmount: Invalid PID");
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][msg.sender];

        (uint256 accPercentPerShare,) = getAccPercentagePerShareAndLastAllocBlock(_pid);

        uint256 userPercentageAllocated = user.amount.mul(accPercentPerShare).div(1e18).sub(user.tokenAllocDebt);
        return userPercentageAllocated.mul(pool.targetRaise).div(TOTAL_TOKEN_ALLOCATION_POINTS);
    }

    // step 2
    function fundPledge(uint256 _pid) external nonReentrant {
        require(_pid < poolInfo.length, "fundPledge: Invalid PID");

        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.pledgeFundingAmount == 0, "fundPledge: Pledge has already been funded");

        require(block.number > pool.stakingEndBlock, "fundPledge: Staking is still taking place");
        require(block.number <= pool.pledgeFundingEndBlock, "fundPledge: Deadline has passed to fund your pledge");

        require(user.amount > 0, "fundPledge: Must have staked");
        uint256 pledgeFundingAmount = getPledgeFundingAmount(_pid);
        require(pledgeFundingAmount > 0, "fundPledge: must have positive pledge amount");

        // this will fail if the sender does not have the right amount of the token
        pool.fundRaisingToken.safeTransferFrom(msg.sender, address(this), pledgeFundingAmount);
        
        poolIdToTotalRaised[_pid] = poolIdToTotalRaised[_pid].add(pledgeFundingAmount);

        (uint256 accPercentPerShare,) = getAccPercentagePerShareAndLastAllocBlock(_pid);
        uint256 userPercentageAllocated = user.amount.mul(accPercentPerShare).div(1e18).sub(user.tokenAllocDebt);
        poolIdToTotalFundedPercentageOfTargetRaise[_pid] = poolIdToTotalFundedPercentageOfTargetRaise[_pid].add(userPercentageAllocated);

        user.pledgeFundingAmount = pledgeFundingAmount; // ensures pledges can only be done once

        stakingToken.safeTransfer(address(msg.sender), user.amount);

        emit PledgeFunded(msg.sender, _pid, pledgeFundingAmount);
    }

    // pre-step 3 for project
    function getTotalRaisedVsTarget(uint256 _pid) external view returns (uint256 raised, uint256 target) {
        return (poolIdToTotalRaised[_pid], poolInfo[_pid].targetRaise);
    }

    // step 3
    function setupVestingRewards(uint256 _pid, uint256 _rewardAmount,  uint256 _rewardStartBlock, uint256 _rewardCliffEndBlock, uint256 _rewardEndBlock)
    external nonReentrant onlyOwner {
        require(_pid < poolInfo.length, "setupVestingRewards: Invalid PID");
        require(_rewardStartBlock > block.number, "setupVestingRewards: start block in the past");
        require(_rewardCliffEndBlock >= _rewardStartBlock, "setupVestingRewards: Cliff must be after or equal to start block");
        require(_rewardEndBlock > _rewardCliffEndBlock, "setupVestingRewards: end block must be after cliff block");

        PoolInfo storage pool = poolInfo[_pid];

        require(block.number > pool.pledgeFundingEndBlock, "setupVestingRewards: Stakers are still pledging");

        uint256 vestingLength = _rewardEndBlock.sub(_rewardStartBlock);

        poolIdToMaxRewardTokensAvailableForVesting[_pid] = _rewardAmount;
        poolIdToRewardPerBlock[_pid] = _rewardAmount.div(vestingLength);

        poolIdToRewardStartBlock[_pid] = _rewardStartBlock;
        poolIdToLastRewardBlock[_pid] = _rewardStartBlock;

        poolIdToRewardCliffEndBlock[_pid] = _rewardCliffEndBlock;

        poolIdToRewardEndBlock[_pid] = _rewardEndBlock;

        pool.rewardToken.safeTransferFrom(msg.sender, address(rewardGuildBank), _rewardAmount);

        emit RewardsSetUp(_pid, _rewardAmount, _rewardEndBlock);
    }

    function pendingRewards(uint256 _pid, address _user) external view returns (uint256) {
        require(_pid < poolInfo.length, "pendingRewards: invalid _pid");

        UserInfo memory user = userInfo[_pid][_user];

        // If they have staked but have not funded their pledge, they are not entitled to rewards
        if (user.pledgeFundingAmount == 0) {
            return 0;
        }

        uint256 accRewardPerShare = poolIdToAccRewardPerShareVesting[_pid];
        uint256 rewardEndBlock = poolIdToRewardEndBlock[_pid];
        uint256 lastRewardBlock = poolIdToLastRewardBlock[_pid];
        uint256 rewardPerBlock = poolIdToRewardPerBlock[_pid];
        if (block.number > lastRewardBlock && rewardEndBlock != 0 && poolIdToTotalStaked[_pid] != 0) {
            uint256 maxEndBlock = block.number <= rewardEndBlock ? block.number : rewardEndBlock;
            uint256 multiplier = getMultiplier(lastRewardBlock, maxEndBlock);
            uint256 reward = multiplier.mul(rewardPerBlock);
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e18).div(poolIdToTotalFundedPercentageOfTargetRaise[_pid]));
        }

        (uint256 accPercentPerShare,) = getAccPercentagePerShareAndLastAllocBlock(_pid);
        uint256 userPercentageAllocated = user.amount.mul(accPercentPerShare).div(1e18).sub(user.tokenAllocDebt);
        return userPercentageAllocated.mul(accRewardPerShare).div(1e18).sub(user.rewardDebtRewards);
    }

    function massUpdatePools() public {
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        require(_pid < poolInfo.length, "updatePool: invalid _pid");

        PoolInfo storage poolInfo = poolInfo[_pid];

        // staking not started
        if (block.number < poolInfo.tokenAllocationStartBlock) {
            return;
        }

        // if no one staked, nothing to do
        if (poolIdToTotalStaked[_pid] == 0) {
            poolIdToLastPercentageAllocBlock[_pid] = block.number;
            return;
        }

        // token allocation not finished
        uint256 maxEndBlockForPercentAlloc = block.number <= poolInfo.stakingEndBlock ? block.number : poolInfo.stakingEndBlock;
        uint256 blocksSinceLastPercentAlloc = getMultiplier(poolIdToLastPercentageAllocBlock[_pid], maxEndBlockForPercentAlloc);

        if (poolIdToRewardEndBlock[_pid] == 0 && blocksSinceLastPercentAlloc > 0) {
            (uint256 accPercentPerShare, uint256 lastAllocBlock) = getAccPercentagePerShareAndLastAllocBlock(_pid);
            poolIdToAccPercentagePerShare[_pid] = accPercentPerShare;
            poolIdToLastPercentageAllocBlock[_pid] = lastAllocBlock;
        }

        // project has not sent rewards
        if (poolIdToRewardEndBlock[_pid] == 0) {
            return;
        }

        // cliff has not passed for pool
        if (block.number < poolIdToRewardCliffEndBlock[_pid]) {
            return;
        }

        uint256 rewardEndBlock = poolIdToRewardEndBlock[_pid];
        uint256 lastRewardBlock = poolIdToLastRewardBlock[_pid];
        uint256 maxEndBlock = block.number <= rewardEndBlock ? block.number : rewardEndBlock;
        uint256 multiplier = getMultiplier(lastRewardBlock, maxEndBlock);

        // No point in doing any more logic as the rewards have ended
        if (multiplier == 0) {
            return;
        }

        uint256 rewardPerBlock = poolIdToRewardPerBlock[_pid];
        uint256 reward = multiplier.mul(rewardPerBlock);

        poolIdToAccRewardPerShareVesting[_pid] = poolIdToAccRewardPerShareVesting[_pid].add(reward.mul(1e18).div(poolIdToTotalFundedPercentageOfTargetRaise[_pid]));
        poolIdToLastRewardBlock[_pid] = maxEndBlock;
    }

    function getAccPercentagePerShareAndLastAllocBlock(uint256 _pid) internal view returns (uint256 accPercentPerShare, uint256 lastAllocBlock) {
        PoolInfo memory poolInfo = poolInfo[_pid];
        uint256 tokenAllocationPeriodInBlocks = poolInfo.stakingEndBlock.sub(poolInfo.tokenAllocationStartBlock);

        uint256 allocationAvailablePerBlock = TOTAL_TOKEN_ALLOCATION_POINTS.div(tokenAllocationPeriodInBlocks);

        uint256 maxEndBlockForPercentAlloc = block.number <= poolInfo.stakingEndBlock ? block.number : poolInfo.stakingEndBlock;
        uint256 multiplier = getMultiplier(poolIdToLastPercentageAllocBlock[_pid], maxEndBlockForPercentAlloc);
        uint256 totalPercentageUnlocked = multiplier.mul(allocationAvailablePerBlock);

        return (
            poolIdToAccPercentagePerShare[_pid].add(totalPercentageUnlocked.mul(1e18).div(poolIdToTotalStaked[_pid])),
            maxEndBlockForPercentAlloc
        );
    }

    function claimReward(uint256 _pid) public nonReentrant {
        updatePool(_pid);

        require(block.number >= poolIdToRewardCliffEndBlock[_pid], "claimReward: Not past cliff");

        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.pledgeFundingAmount > 0, "claimReward: Nice try pal");

        PoolInfo storage pool = poolInfo[_pid];

        uint256 accRewardPerShare = poolIdToAccRewardPerShareVesting[_pid];

        (uint256 accPercentPerShare,) = getAccPercentagePerShareAndLastAllocBlock(_pid);
        uint256 userPercentageAllocated = user.amount.mul(accPercentPerShare).div(1e18).sub(user.tokenAllocDebt);
        uint256 pending = userPercentageAllocated.mul(accRewardPerShare).div(1e18).sub(user.rewardDebtRewards);

        if (pending > 0) {
            user.rewardDebtRewards = userPercentageAllocated.mul(accRewardPerShare).div(1e18);
            safeRewardTransfer(pool.rewardToken, msg.sender, pending);

            emit RewardClaimed(msg.sender, _pid, pending);
        }
    }

    // withdraw only permitted post `pledgeFundingEndBlock` and you can only take out full amount if you did not fund the pledge
    // functions like the old emergency withdraw as it does not concern itself with claiming rewards
    function withdraw(uint256 _pid) external nonReentrant {
        require(_pid < poolInfo.length, "withdraw: invalid _pid");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount > 0, "withdraw: No stake to withdraw");
        require(user.pledgeFundingAmount == 0, "withdraw: Only allow non-funders to withdraw");
        require(block.number > pool.pledgeFundingEndBlock, "withdraw: Not yet permitted");

        uint256 withdrawAmount = user.amount;

        // remove the record for this user
        delete userInfo[_pid][msg.sender];

        stakingToken.safeTransfer(msg.sender, withdrawAmount);

        emit Withdraw(msg.sender, _pid, withdrawAmount);
    }

    function claimFundRaising(uint256 _pid) external nonReentrant onlyOwner {
        require(_pid < poolInfo.length, "claimFundRaising: invalid _pid");
        PoolInfo storage pool = poolInfo[_pid];

        uint256 rewardPerBlock = poolIdToRewardPerBlock[_pid];
        require(rewardPerBlock != 0, "claimFundRaising: rewards not yet sent");
        require(poolIdToFundsClaimed[_pid] == false, "claimFundRaising: Already claimed funds");

        poolIdToFundsClaimed[_pid] = true;
        // this will fail if the sender does not have the right amount of the token
        pool.fundRaisingToken.transfer(owner(), poolIdToTotalRaised[_pid]);

        emit FundRaisingClaimed(_pid, owner(), poolIdToTotalRaised[_pid]);
    }

    ////////////
    // Private /
    ////////////

    /// @dev Safe reward transfer function, just in case if rounding error causes pool to not have enough rewards.

    function safeRewardTransfer(IERC20 _rewardToken, address _to, uint256 _amount) private {
        uint256 bal = rewardGuildBank.tokenBalance(_rewardToken);
        if (_amount > bal) {
            rewardGuildBank.withdrawTo(_rewardToken, _to, bal);
        } else {
            rewardGuildBank.withdrawTo(_rewardToken, _to, _amount);
        }
    }

    /// @notice Return reward multiplier over the given _from to _to block.
    /// @param _from Block number
    /// @param _to Block number
    /// @return Number of blocks that have passed
    function getMultiplier(uint256 _from, uint256 _to) private view returns (uint256) {
        return _to.sub(_from);
    }
}