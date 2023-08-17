//SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

/**
 * @title Minting
 * @author gotbit
 * @notice Contract for staking tokens in order to earn rewards. Any user can make multiple stakes. Reward earn period is practically unlimited.
 */

contract Minting is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    // TYPES

    struct Stake {
        address owner;
        uint128 amount;
        uint128 earned;
        uint256 userRewardPerTokenPaid;
        uint32 unstakedAtBlockNumber;
        uint32 unstakedAtBlockTimestamp;
        uint32 stakingPeriod;
        uint32 timestamp;
    }

    // STATE VARIABLES

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;
    address public penaltyWallet;

    uint128 public rewardRate;
    uint128 public rewardsRemaining;

    uint256 public rewardPerTokenStored;
    uint256 public totalSupply;

    uint80 public periodFinish;
    uint80 public rewardsDuration = 365 days; // 1 year
    uint80 public lastUpdateTime;
    uint256 public firstRewardPeriodStart;

    uint256 public maxPotentialDebt;
    uint256 public previousActiveReward;
    uint256 public currentRewardPaid;

    uint256 public constant ACCURACY = 1e18;
    uint256 public constant MIN_STAKING_PERIOD = 1 days;
    uint256 public constant RECEIVE_PERIOD = 14 days;
    uint256 public constant MIN_REWARDS_DURATION = 365 days; // 1 years

    mapping(uint256 => Stake) public stakes;
    mapping(address => uint256[]) public userInactiveStakes;
    mapping(address => EnumerableSet.UintSet) private idsByUser;

    mapping(address => uint256) public userBalances;

    uint256 public globalId;

    // sum of all staking periods across all active stakes
    uint128 public sumOfActiveStakingPeriods;
    // number of currenlty active stakes
    uint128 public numOfActiveStakes;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 indexed id, uint256 amount);
    event Withdrawn(address user, uint256 indexed id, uint256 amount);
    event RewardPaid(address user, uint256 indexed id, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event PenaltyWalletUpdated(address newWallet);

    constructor(
        IERC20 stakingToken_,
        IERC20 rewardToken_,
        address owner_,
        address penaltyWallet_
    ) {
        require(address(stakingToken_) != address(0), 'Invalid address');
        require(address(rewardToken_) != address(0), 'Invalid address');
        require(penaltyWallet_ != address(0), 'Invalid address');
        require(owner_ != address(0), 'Invalid address');

        stakingToken = stakingToken_;
        rewardToken = rewardToken_;
        transferOwnership(owner_);
        penaltyWallet = penaltyWallet_;
    }

    /// @dev Update rewards pool information to correct rewards calculation for global varialbes and current id variables
    /// @param id stake to update info for
    modifier updateReward(uint256 id) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (id != 0) {
            stakes[id].earned = earned(id);
            stakes[id].userRewardPerTokenPaid = rewardPerTokenStored;
        }
        _;
    }

    /// @dev Allows user to stake tokens
    /// @param amount of token to stake
    /// @param stakingPeriod period to hold staked tokens (in case of unstake too early or too late => penalties applied)
    function stake(
        uint128 amount,
        uint32 stakingPeriod
    ) external whenNotPaused updateReward(0) {
        require(amount > 0, 'Cannot stake 0');
        require(stakingPeriod >= MIN_STAKING_PERIOD, 'Staking period is too short');
        require(periodFinish >= block.timestamp, 'Reward period not activated');

        // Getting the maximum possible potential debt
        if (totalSupply == 0 && uint80(block.timestamp) < periodFinish) {
            maxPotentialDebt =
                (periodFinish - uint80(block.timestamp)) *
                uint256(rewardRate);
        }

        totalSupply += amount;
        sumOfActiveStakingPeriods += stakingPeriod;
        ++numOfActiveStakes;

        // address owner;
        // uint128 amount;
        // uint128 earned;
        // uint256 userRewardPerTokenPaid;
        // uint32 unstakedAtBlockNumber;
        // uint32 unstakedAtBlockTimestamp;
        // uint32 stakingPeriod;
        // uint32 timestamp;
        stakes[++globalId] = Stake(
            msg.sender,
            amount,
            0,
            rewardPerTokenStored,
            0,
            0,
            stakingPeriod,
            uint32(block.timestamp)
        );

        userBalances[msg.sender] += amount;
        idsByUser[msg.sender].add(globalId);

        emit Staked(msg.sender, globalId, amount);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @dev Allows to calculate principal and rewards penalties (nominated in percents, multiplied by ACCURACY = 1e18) for a specific stake
    /// @param id Stake id
    /// @return principalPenaltyPercentage - principal fee, rewardPenaltyPercentage - rewards fee (multiplied by ACCURACY)
    function calculatePenalties(
        uint256 id
    )
        public
        view
        returns (uint256 principalPenaltyPercentage, uint256 rewardPenaltyPercentage)
    {
        uint128 timestamp = stakes[id].timestamp;
        uint128 stakingPeriod = stakes[id].stakingPeriod;
        uint256 actualStakingTime = block.timestamp - timestamp;

        if (actualStakingTime <= stakingPeriod) {
            // EMERGENCY UNSTAKE
            if (actualStakingTime < (2 * stakingPeriod) / 10) {
                // 0 - 20 % hold time
                principalPenaltyPercentage = 80 * ACCURACY;
                rewardPenaltyPercentage = 100 * ACCURACY;
            } else if (actualStakingTime < (4 * stakingPeriod) / 10) {
                // 20 - 40 % hold time
                principalPenaltyPercentage = 40 * ACCURACY;
                rewardPenaltyPercentage = 100 * ACCURACY;
            } else if (actualStakingTime < (5 * stakingPeriod) / 10) {
                // 40 - 50 % hold time
                rewardPenaltyPercentage = 100 * ACCURACY;
            } else if (actualStakingTime < (7 * stakingPeriod) / 10) {
                // 50 - 70 % hold time
                rewardPenaltyPercentage = 50 * ACCURACY;
            } else {
                // 70 - 100 % hold time
                rewardPenaltyPercentage = 20 * ACCURACY;
            }
        } else if (actualStakingTime > stakingPeriod + RECEIVE_PERIOD) {
            // LATE UNSTAKE
            // principal penalty = 0

            uint256 extraPeriod = actualStakingTime - stakingPeriod;
            rewardPenaltyPercentage = (extraPeriod * 100 * ACCURACY) / actualStakingTime;
        }
        // else SAFE UNSTAKE (principal fee = 0, rewards fee = 0)
    }

    /// @dev Allows user to withdraw staked tokens + claim earned rewards - penalties
    /// @param id Stake id
    function withdraw(uint256 id) external updateReward(id) {
        Stake memory _stake = stakes[id];
        uint256 amount = _stake.amount;
        require(_stake.unstakedAtBlockNumber == 0, 'Already unstaked');
        require(_stake.owner == msg.sender, 'Can`t be called not by stake owner');

        totalSupply -= amount;
        userBalances[msg.sender] -= amount;

        (
            uint256 principalPenaltyPercentage,
            uint256 rewardPenaltyPercentage
        ) = calculatePenalties(id);

        emit Withdrawn(msg.sender, id, amount);

        --numOfActiveStakes;
        sumOfActiveStakingPeriods -= stakes[id].stakingPeriod;

        uint256 rewardAmountToWallet;
        uint256 rewardAmountToUser;

        uint256 reward = stakes[id].earned;

        if (_stake.earned != 0) {
            // CLAIM ALL EARNED REWARDS
            currentRewardPaid += reward;

            rewardAmountToWallet = (reward * rewardPenaltyPercentage) / (100 * ACCURACY);

            rewardAmountToUser = reward - rewardAmountToWallet;

            emit RewardPaid(msg.sender, id, rewardAmountToWallet);
        }

        if (totalSupply == 0) {
            maxPotentialDebt = 0;

            // previous rewards become 0 when all active stakes are unstaked
            previousActiveReward = 0;
        } else {
            maxPotentialDebt -= reward;
        }

        idsByUser[msg.sender].remove(id);
        userInactiveStakes[msg.sender].push(id);

        //stakes[id].amount = 0;
        stakes[id].unstakedAtBlockNumber = uint32(block.number);
        stakes[id].unstakedAtBlockTimestamp = uint32(block.timestamp);

        // ALL TOKENS TRANSFERS -------------------------------------------------------

        // REWARDS

        if (rewardAmountToUser != 0) {
            rewardToken.safeTransfer(msg.sender, rewardAmountToUser);
        }

        if (rewardAmountToWallet != 0) {
            rewardToken.safeTransfer(penaltyWallet, rewardAmountToWallet);
        }

        // PRINCIPAL

        uint256 amountToWallet = (amount * principalPenaltyPercentage) / (100 * ACCURACY);
        if (amountToWallet != 0) {
            stakingToken.safeTransfer(penaltyWallet, amountToWallet);
        }

        // amount != amountToWallet due to the technical design
        stakingToken.safeTransfer(msg.sender, amount - amountToWallet);
    }

    /// @dev Allows to set reward rate
    /// @param newRewardRate is amount of tokens (in token weis) will be distributed per second (rewards / rewardsDuration)
    function _notifyRewardAmount(uint128 newRewardRate) private {
        uint128 reward = uint128(newRewardRate * rewardsDuration);

        // if there is at least one stakeholder => rewards keep being earned
        if (totalSupply != 0 && periodFinish != 0) {
            // previous rewards exist only if at least one staking period has been set
            // REWARDS_TOTAL = PAID_UNSTAKED + EARNED_ACTIVE + LEFTOVER_ACTIVE
            uint256 previousPeriodLeftover = rewardRate *
                (periodFinish - lastTimeRewardApplicable());

            previousActiveReward =
                (rewardRate * rewardsDuration) -
                previousPeriodLeftover -
                currentRewardPaid;
        } else {
            previousActiveReward = 0;
        }

        currentRewardPaid = 0;

        if (block.timestamp >= periodFinish) {
            rewardRate = (reward + rewardsRemaining) / rewardsDuration;
            rewardsRemaining = (reward + rewardsRemaining) % rewardsDuration;
        } else {
            uint80 remaining = periodFinish - uint80(block.timestamp);
            uint128 leftover = remaining * rewardRate + rewardsRemaining;
            rewardRate = (reward + leftover) / rewardsDuration;
            rewardsRemaining = (reward + leftover) % rewardsDuration;
        }

        require(rewardRate != 0, 'Actual reward rate is too low');

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        uint256 balance = address(rewardToken) == address(stakingToken)
            ? rewardToken.balanceOf(address(this)) - totalSupply
            : rewardToken.balanceOf(address(this));

        if (totalSupply != 0) {
            maxPotentialDebt = rewardRate * rewardsDuration;

            // Ensure the balance in the contract is more than the maximum potential debt
            require(maxPotentialDebt <= balance, 'Provided reward too high');
        }

        lastUpdateTime = uint80(block.timestamp);
        periodFinish = uint80(block.timestamp) + rewardsDuration;
        if (firstRewardPeriodStart == 0) {
            firstRewardPeriodStart = block.timestamp;
        }
        emit RewardAdded(reward);
    }

    /// @dev Allows owner to set new reward rate
    /// @param newRewardRate is amount of tokens (in token weis) will be distributed per second (rewards / rewardsDuration)
    function notifyRewardAmount(
        uint128 newRewardRate
    ) external onlyOwner updateReward(0) {
        _notifyRewardAmount(newRewardRate);
    }

    /// @dev Allows owner to set previous reward rate
    function notifyRewardAmountPrevious() external onlyOwner updateReward(0) {
        require(rewardRate != 0, 'Previous reward rate is too low');
        _notifyRewardAmount(rewardRate);
    }

    /// @dev Allows owner to set period of rewards distribution
    /// @param rewardsDuration_ is new rewardsDuration amount
    function setRewardsDuration(uint80 rewardsDuration_) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            'Previous rewards period must be complete before changing the duration for the new period'
        );
        require(
            rewardsDuration_ >= MIN_REWARDS_DURATION,
            'Rewards duration is too short'
        );
        require(rewardsDuration_ != rewardsDuration, 'Rewards duration duplicate');
        rewardsDuration = rewardsDuration_;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /// @dev Allows owner to set penalty wallet
    /// @param penaltyWallet_ is new penalty wallet
    function setPenaltyWallet(address penaltyWallet_) external onlyOwner {
        require(
            penaltyWallet_ != address(0) && penaltyWallet_ != penaltyWallet,
            'Invalid penalty wallet'
        );
        penaltyWallet = penaltyWallet_;
        emit PenaltyWalletUpdated(penaltyWallet);
    }

    /// @dev Allows to view last action time in the contract
    /// @return timestamp of last action
    function lastTimeRewardApplicable() public view returns (uint80) {
        return block.timestamp < periodFinish ? uint80(block.timestamp) : periodFinish;
    }

    /// @dev Allows to view already distributed rewards
    /// @return rewardPerTokenStored for current moment
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) *
                uint256(rewardRate) *
                ACCURACY) / totalSupply);
    }

    /// @dev Allows to view current user earned rewards
    /// @param id to view rewards
    /// @return earnedAmount of rewards for selected user
    function earned(uint256 id) public view returns (uint128) {
        Stake memory _stake = stakes[id];
        if (_stake.unstakedAtBlockNumber == 0) {
            // ACTIVE STAKE => calculate amount + increase reward per token
            return
                uint128(
                    (_stake.amount * (rewardPerToken() - _stake.userRewardPerTokenPaid)) /
                        ACCURACY +
                        _stake.earned
                );
        }

        // INACTIVE STAKE
        return 0;
    }

    /// @dev Allows to view staking amount of selected user
    /// @param account to view balance
    /// @return balance of staking tokens for selected account
    function balanceOf(address account) external view returns (uint256) {
        return userBalances[account];
    }

    /// @dev Allows to view user stake ids
    /// @param user user account
    /// @return array of user ids
    function getUserStakeIds(address user) external view returns (uint256[] memory) {
        return idsByUser[user].values();
    }

    /// @dev Allows to view user`s stake ids quantity
    /// @param user user account
    /// @return length of user ids array
    function getUserStakeIdsLength(address user) external view returns (uint256) {
        return idsByUser[user].values().length;
    }

    /// @dev Allows to view if a user has a stake with specific id
    /// @param user user account
    /// @param id stake id
    /// @return bool flag (true if a user has owns the id)
    function hasStakeId(address user, uint256 id) external view returns (bool) {
        return idsByUser[user].contains(id);
    }

    /// @dev Allows to get all user stakes
    /// @param user user account
    /// @return array of user stakes
    function getAllUserStakes(address user) external view returns (Stake[] memory) {
        uint256[] memory ids = idsByUser[user].values();
        uint256 len = ids.length;
        Stake[] memory userStakes = new Stake[](len);
        for (uint256 i; i < len; ++i) {
            uint256 stakeId = ids[i];
            userStakes[i] = stakes[stakeId];
            userStakes[i].earned = earned(stakeId);
        }

        return userStakes;
    }

    /// @dev Allows to get a slice user stakes array
    /// @param user user account
    /// @param startIndex Starting index in user ids array
    /// @param length return array length
    /// @return Array-slice of user stakes
    function getUserStakesSlice(
        address user,
        uint256 startIndex,
        uint256 length
    ) external view returns (Stake[] memory) {
        uint256[] memory ids = idsByUser[user].values();
        uint256 len = ids.length;
        require(startIndex + length <= len, 'Invalid startIndex + length');

        Stake[] memory userStakes = new Stake[](length);
        uint256 userIndex;
        for (uint256 i = startIndex; i < startIndex + length; ++i) {
            uint256 stakeId = ids[i];
            userStakes[userIndex] = stakes[stakeId];
            userStakes[userIndex].earned = earned(stakeId);
            ++userIndex;
        }

        return userStakes;
    }

    /// @dev Returns the approximate APR for a specific stake position including penalties (real APR = potential APR * (1 - rewardPenalty)), when TVL == 0 => returns 0
    /// @param id stake id
    /// @return APR value multiplied by 10**18
    function getAPR(uint256 id) external view returns (uint256) {
        (, uint256 rewardPenalty) = calculatePenalties(id);

        uint256 _tvl = totalSupply;

        if (_tvl == 0) return 0;
        return
            (uint256(rewardRate) *
                ACCURACY *
                365 days *
                100 *
                (100 * ACCURACY - rewardPenalty)) / (_tvl * 100 * ACCURACY); // earned user value in tokens for one second including share (1e18 for accuracy)
    }

    /// @dev Sets paused state for the contract (can be called by the owner only)
    /// @param paused paused flag
    function setPaused(bool paused) external onlyOwner {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// @dev Allows to get a slice user stakes history array
    /// @param user user account
    /// @param startIndex Starting index in user ids array
    /// @param length return array length
    /// @return Array-slice of user stakes history
    function getUserInactiveStakesSlice(
        address user,
        uint256 startIndex,
        uint256 length
    ) external view returns (Stake[] memory) {
        uint256 len = userInactiveStakes[user].length;
        require(startIndex + length <= len, 'Invalid startIndex + length');
        Stake[] memory userStakes = new Stake[](length);
        uint256[] memory userInactiveStakes_ = userInactiveStakes[user];
        uint256 userIndex;
        for (uint256 i = startIndex; i < startIndex + length; ++i) {
            uint256 stakeId = userInactiveStakes_[i];
            userStakes[userIndex] = stakes[stakeId];
            ++userIndex;
        }
        return userStakes;
    }

    /// @dev Allows to view user`s closed stakes quantity
    /// @param user user account
    /// @return length of user closed stakes array
    function getUserInactiveStakesLength(address user) external view returns (uint256) {
        return userInactiveStakes[user].length;
    }

    /// @dev Allows to view total cumulative unclaimed rewards (earned by all users)
    /// @return rewards (nominated in token weis)
    function getTotalRewards() external view returns (uint256) {
        if (periodFinish != 0 && totalSupply != 0) {
            uint256 periodStart = periodFinish - rewardsDuration;
            uint256 timePassed = lastTimeRewardApplicable() - periodStart;
            return rewardRate * timePassed + previousActiveReward - currentRewardPaid;
        } else {
            return 0;
        }
    }

    /// @dev Returns the approximate APR for a specific stake position not including penalties, when TVL == 0 => returns 0
    /// @return APR value multiplied by 10**18
    function getPotentialAPR() external view returns (uint256) {
        uint256 _tvl = totalSupply;

        if (_tvl == 0) return 0;
        return (uint256(rewardRate) * ACCURACY * 365 days * 100) / (_tvl); // earned user value in tokens for one second including share (1e18 for accuracy)
    }
}