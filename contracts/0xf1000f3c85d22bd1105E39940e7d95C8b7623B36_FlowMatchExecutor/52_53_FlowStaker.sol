// SPDX-License-Identifier: MIT
// solhint-disable not-rely-on-time
pragma solidity 0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title FlowStaker
 * @author nneverlander. Twitter @nneverlander
 * @notice The staker contract that allows people to stake tokens and earn voting power to be used in curation and possibly other places
 */
contract FlowStaker is Ownable, Pausable {
    struct StakeAmount {
        uint256 amount;
        uint256 timestamp;
    }

    enum Duration {
        NONE,
        THREE_MONTHS,
        SIX_MONTHS,
        TWELVE_MONTHS
    }

    enum StakeLevel {
        NONE,
        BRONZE,
        SILVER,
        GOLD,
        PLATINUM
    }

    ///@dev Storage variable to keep track of the staker's staked duration and amounts
    mapping(address => mapping(Duration => StakeAmount))
        public userstakedAmounts;

    ///@dev Flow token address
    // solhint-disable var-name-mixedcase
    address public immutable FLOW_TOKEN;

    ///@dev Flow treasury address - will be a EOA/multisig
    address public flowTreasury;

    /**@dev Power levels to reach the specified stake thresholds. Users can reach these levels 
          either by staking the specified number of tokens for no duration or a less number of tokens but with higher durations.
          See getUserStakePower() to see how users can reach these levels.
  */
    uint32 public bronzeStakeThreshold = 1000;
    uint32 public silverStakeThreshold = 5000;
    uint32 public goldStakeThreshold = 10000;
    uint32 public platinumStakeThreshold = 20000;

    ///@dev Penalties if staked tokens are rageQuit early. Example: If 100 tokens are staked for twelve months but rageQuit right away,
    /// the user will get back 100/4 tokens.
    uint32 public threeMonthPenalty = 2;
    uint32 public sixMonthPenalty = 3;
    uint32 public twelveMonthPenalty = 4;

    event Staked(address indexed user, uint256 amount, Duration duration);
    event DurationChanged(
        address indexed user,
        uint256 amount,
        Duration oldDuration,
        Duration newDuration
    );
    event UnStaked(address indexed user, uint256 amount);
    event RageQuit(address indexed user, uint256 totalToUser, uint256 penalty);
    event RageQuitPenaltiesUpdated(
        uint32 threeMonth,
        uint32 sixMonth,
        uint32 twelveMonth
    );
    event StakeLevelThresholdUpdated(StakeLevel stakeLevel, uint32 threshold);

    /**
    @param _tokenAddress The address of the Flow token contract
    @param _flowTreasury The address of the Flow treasury used for sending rageQuit penalties
   */
    constructor(address _tokenAddress, address _flowTreasury) {
        FLOW_TOKEN = _tokenAddress;
        flowTreasury = _flowTreasury;
    }

    // =================================================== USER FUNCTIONS =======================================================

    /**
     * @notice Stake tokens for a specified duration
     * @dev Tokens are transferred from the user to this contract
     * @param amount Amount of tokens to stake
     * @param duration Duration of the stake
     */
    function stake(uint256 amount, Duration duration) external whenNotPaused {
        require(amount != 0, "stake amount cant be 0");
        // update storage
        userstakedAmounts[msg.sender][duration].amount += amount;
        userstakedAmounts[msg.sender][duration].timestamp = block.timestamp;
        // perform transfer; no need for safeTransferFrom since we know the implementation of the token contract
        IERC20(FLOW_TOKEN).transferFrom(msg.sender, address(this), amount);
        // emit event
        emit Staked(msg.sender, amount, duration);
    }

    /**
     * @notice Change duration of staked tokens
     * @dev Duration can be changed from low to high but not from high to low. State updates are performed
     * @param amount Amount of tokens to change duration
     * @param oldDuration Old duration of the stake
     * @param newDuration New duration of the stake
     */
    function changeDuration(
        uint256 amount,
        Duration oldDuration,
        Duration newDuration
    ) external whenNotPaused {
        require(amount != 0, "amount cant be 0");
        require(
            userstakedAmounts[msg.sender][oldDuration].amount >= amount,
            "insuf stake to change duration"
        );
        require(newDuration > oldDuration, "new duration must exceed old");

        // update storage
        userstakedAmounts[msg.sender][oldDuration].amount -= amount;
        userstakedAmounts[msg.sender][newDuration].amount += amount;
        // update timestamp for new duration
        userstakedAmounts[msg.sender][newDuration].timestamp = block.timestamp;
        // only update old duration timestamp if old duration amount is 0
        if (userstakedAmounts[msg.sender][oldDuration].amount == 0) {
            delete userstakedAmounts[msg.sender][oldDuration].timestamp;
        }
        // emit event
        emit DurationChanged(msg.sender, amount, oldDuration, newDuration);
    }

    /**
     * @notice Unstake tokens
     * @dev Storage updates are done for each stake level. See _updateUserStakedAmounts for more details
     * @param amount Amount of tokens to unstake
     */
    function unstake(uint256 amount) external whenNotPaused {
        require(amount != 0, "unstake amount cant be 0");
        uint256 noVesting = userstakedAmounts[msg.sender][Duration.NONE].amount;
        uint256 vestedThreeMonths = getVestedAmount(
            msg.sender,
            Duration.THREE_MONTHS
        );
        uint256 vestedSixMonths = getVestedAmount(
            msg.sender,
            Duration.SIX_MONTHS
        );
        uint256 vestedTwelveMonths = getVestedAmount(
            msg.sender,
            Duration.TWELVE_MONTHS
        );
        uint256 totalVested = noVesting +
            vestedThreeMonths +
            vestedSixMonths +
            vestedTwelveMonths;
        require(totalVested >= amount, "insufficient balance to unstake");

        // update storage
        _updateUserStakedAmounts(
            msg.sender,
            amount,
            noVesting,
            vestedThreeMonths,
            vestedSixMonths,
            vestedTwelveMonths
        );
        // perform transfer
        IERC20(FLOW_TOKEN).transfer(msg.sender, amount);
        // emit event
        emit UnStaked(msg.sender, amount);
    }

    /**
     * @notice Ragequit tokens. Applies penalties for unvested tokens
     */
    function rageQuit() external {
        (uint256 totalToUser, uint256 penalty) = getRageQuitAmounts(msg.sender);
        // update storage
        _clearUserStakedAmounts(msg.sender);
        // perform transfers
        IERC20(FLOW_TOKEN).transfer(msg.sender, totalToUser);
        IERC20(FLOW_TOKEN).transfer(flowTreasury, penalty);
        // emit event
        emit RageQuit(msg.sender, totalToUser, penalty);
    }

    // ====================================================== VIEW FUNCTIONS ======================================================

    /**
     * @notice Get total staked tokens for a user for all durations
     * @param user address of the user
     * @return total amount of tokens staked by the user
     */
    function getUserTotalStaked(address user) external view returns (uint256) {
        return
            userstakedAmounts[user][Duration.NONE].amount +
            userstakedAmounts[user][Duration.THREE_MONTHS].amount +
            userstakedAmounts[user][Duration.SIX_MONTHS].amount +
            userstakedAmounts[user][Duration.TWELVE_MONTHS].amount;
    }

    /**
     * @notice Get total vested tokens for a user for all durations
     * @param user address of the user
     * @return total amount of vested tokens for the user
     */
    function getUserTotalVested(address user) external view returns (uint256) {
        return
            getVestedAmount(user, Duration.NONE) +
            getVestedAmount(user, Duration.THREE_MONTHS) +
            getVestedAmount(user, Duration.SIX_MONTHS) +
            getVestedAmount(user, Duration.TWELVE_MONTHS);
    }

    /**
     * @notice Gets rageQuit amounts for a user after applying penalties
     * @dev Penalty amounts are sent to Flow treasury
     * @param user address of the user
     * @return Total amount to user and penalties
     */
    function getRageQuitAmounts(
        address user
    ) public view returns (uint256, uint256) {
        uint256 noLock = userstakedAmounts[user][Duration.NONE].amount;
        uint256 threeMonthLock = userstakedAmounts[user][Duration.THREE_MONTHS]
            .amount;
        uint256 sixMonthLock = userstakedAmounts[user][Duration.SIX_MONTHS]
            .amount;
        uint256 twelveMonthLock = userstakedAmounts[user][
            Duration.TWELVE_MONTHS
        ].amount;

        uint256 totalStaked = noLock +
            threeMonthLock +
            sixMonthLock +
            twelveMonthLock;
        require(totalStaked != 0, "nothing staked to rage quit");

        uint256 threeMonthVested = getVestedAmount(user, Duration.THREE_MONTHS);
        uint256 sixMonthVested = getVestedAmount(user, Duration.SIX_MONTHS);
        uint256 twelveMonthVested = getVestedAmount(
            user,
            Duration.TWELVE_MONTHS
        );

        uint256 totalVested = noLock +
            threeMonthVested +
            sixMonthVested +
            twelveMonthVested;

        uint256 totalToUser = totalVested +
            ((threeMonthLock - threeMonthVested) / threeMonthPenalty) +
            ((sixMonthLock - sixMonthVested) / sixMonthPenalty) +
            ((twelveMonthLock - twelveMonthVested) / twelveMonthPenalty);

        uint256 penalty = totalStaked - totalToUser;

        return (totalToUser, penalty);
    }

    /**
     * @notice Gets a user's stake level
     * @param user address of the user
     * @return StakeLevel
     */
    function getUserStakeLevel(
        address user
    ) external view returns (StakeLevel) {
        uint256 totalPower = getUserStakePower(user);

        if (totalPower <= bronzeStakeThreshold) {
            return StakeLevel.NONE;
        } else if (totalPower <= silverStakeThreshold) {
            return StakeLevel.BRONZE;
        } else if (totalPower <= goldStakeThreshold) {
            return StakeLevel.SILVER;
        } else if (totalPower <= platinumStakeThreshold) {
            return StakeLevel.GOLD;
        } else {
            return StakeLevel.PLATINUM;
        }
    }

    /**
     * @notice Gets a user stake power. Used to determine voting power in curating collections and possibly other places
     * @dev Tokens staked for higher duration apply a multiplier
     * @param user address of the user
     * @return user stake power
     */
    function getUserStakePower(address user) public view returns (uint256) {
        return
            ((userstakedAmounts[user][Duration.NONE].amount) +
                (userstakedAmounts[user][Duration.THREE_MONTHS].amount * 2) +
                (userstakedAmounts[user][Duration.SIX_MONTHS].amount * 3) +
                (userstakedAmounts[user][Duration.TWELVE_MONTHS].amount * 4)) /
            (1e18);
    }

    /**
     * @notice Returns staking info for a user's staked amounts for different durations
     * @param user address of the user
     * @return Staking amounts for different durations
     */
    function getStakingInfo(
        address user
    ) external view returns (StakeAmount[] memory) {
        StakeAmount[] memory stakingInfo = new StakeAmount[](4);
        stakingInfo[0] = userstakedAmounts[user][Duration.NONE];
        stakingInfo[1] = userstakedAmounts[user][Duration.THREE_MONTHS];
        stakingInfo[2] = userstakedAmounts[user][Duration.SIX_MONTHS];
        stakingInfo[3] = userstakedAmounts[user][Duration.TWELVE_MONTHS];
        return stakingInfo;
    }

    /**
     * @notice Returns vested amount for a user for a given duration
     * @param user address of the user
     * @param duration the duration
     * @return Vested amount for the given duration
     */
    function getVestedAmount(
        address user,
        Duration duration
    ) public view returns (uint256) {
        uint256 timestamp = userstakedAmounts[user][duration].timestamp;
        // short circuit if no vesting for this duration
        if (timestamp == 0) {
            return 0;
        }
        uint256 durationInSeconds = _getDurationInSeconds(duration);
        uint256 secondsSinceStake = block.timestamp - timestamp;
        uint256 amount = userstakedAmounts[user][duration].amount;
        return secondsSinceStake >= durationInSeconds ? amount : 0;
    }

    // ====================================================== INTERNAL FUNCTIONS ================================================

    function _getDurationInSeconds(
        Duration duration
    ) internal pure returns (uint256) {
        if (duration == Duration.THREE_MONTHS) {
            return 90 days;
        } else if (duration == Duration.SIX_MONTHS) {
            return 180 days;
        } else if (duration == Duration.TWELVE_MONTHS) {
            return 360 days;
        } else {
            return 0 seconds;
        }
    }

    /** @notice Update user staked amounts for different duration on unstake
     * @dev A more elegant recursive function is possible but this is more gas efficient
     */
    function _updateUserStakedAmounts(
        address user,
        uint256 amount,
        uint256 noVesting,
        uint256 vestedThreeMonths,
        uint256 vestedSixMonths,
        uint256 vestedTwelveMonths
    ) internal {
        if (amount > noVesting) {
            delete userstakedAmounts[user][Duration.NONE].amount;
            delete userstakedAmounts[user][Duration.NONE].timestamp;
            amount = amount - noVesting;
            if (amount > vestedThreeMonths) {
                if (vestedThreeMonths != 0) {
                    delete userstakedAmounts[user][Duration.THREE_MONTHS]
                        .amount;
                    delete userstakedAmounts[user][Duration.THREE_MONTHS]
                        .timestamp;
                    amount = amount - vestedThreeMonths;
                }
                if (amount > vestedSixMonths) {
                    if (vestedSixMonths != 0) {
                        delete userstakedAmounts[user][Duration.SIX_MONTHS]
                            .amount;
                        delete userstakedAmounts[user][Duration.SIX_MONTHS]
                            .timestamp;
                        amount = amount - vestedSixMonths;
                    }
                    if (amount > vestedTwelveMonths) {
                        revert("should not happen");
                    } else {
                        userstakedAmounts[user][Duration.TWELVE_MONTHS]
                            .amount -= amount;
                        if (
                            userstakedAmounts[user][Duration.TWELVE_MONTHS]
                                .amount == 0
                        ) {
                            delete userstakedAmounts[user][
                                Duration.TWELVE_MONTHS
                            ].timestamp;
                        }
                    }
                } else {
                    userstakedAmounts[user][Duration.SIX_MONTHS]
                        .amount -= amount;
                    if (
                        userstakedAmounts[user][Duration.SIX_MONTHS].amount == 0
                    ) {
                        delete userstakedAmounts[user][Duration.SIX_MONTHS]
                            .timestamp;
                    }
                }
            } else {
                userstakedAmounts[user][Duration.THREE_MONTHS].amount -= amount;
                if (
                    userstakedAmounts[user][Duration.THREE_MONTHS].amount == 0
                ) {
                    delete userstakedAmounts[user][Duration.THREE_MONTHS]
                        .timestamp;
                }
            }
        } else {
            userstakedAmounts[user][Duration.NONE].amount -= amount;
            if (userstakedAmounts[user][Duration.NONE].amount == 0) {
                delete userstakedAmounts[user][Duration.NONE].timestamp;
            }
        }
    }

    /// @dev clears staking info for a user on rageQuit
    function _clearUserStakedAmounts(address user) internal {
        // clear amounts
        delete userstakedAmounts[user][Duration.NONE].amount;
        delete userstakedAmounts[user][Duration.THREE_MONTHS].amount;
        delete userstakedAmounts[user][Duration.SIX_MONTHS].amount;
        delete userstakedAmounts[user][Duration.TWELVE_MONTHS].amount;

        // clear timestamps
        delete userstakedAmounts[user][Duration.NONE].timestamp;
        delete userstakedAmounts[user][Duration.THREE_MONTHS].timestamp;
        delete userstakedAmounts[user][Duration.SIX_MONTHS].timestamp;
        delete userstakedAmounts[user][Duration.TWELVE_MONTHS].timestamp;
    }

    // ====================================================== ADMIN FUNCTIONS ================================================

    /// @dev Admin function to update stake level thresholds
    function updateStakeLevelThreshold(
        StakeLevel stakeLevel,
        uint32 threshold
    ) external onlyOwner {
        if (stakeLevel == StakeLevel.BRONZE) {
            bronzeStakeThreshold = threshold;
        } else if (stakeLevel == StakeLevel.SILVER) {
            silverStakeThreshold = threshold;
        } else if (stakeLevel == StakeLevel.GOLD) {
            goldStakeThreshold = threshold;
        } else if (stakeLevel == StakeLevel.PLATINUM) {
            platinumStakeThreshold = threshold;
        }
        emit StakeLevelThresholdUpdated(stakeLevel, threshold);
    }

    /// @dev Admin function to update rageQuit penalties
    function updatePenalties(
        uint32 _threeMonthPenalty,
        uint32 _sixMonthPenalty,
        uint32 _twelveMonthPenalty
    ) external onlyOwner {
        require(
            _threeMonthPenalty > 0 && _threeMonthPenalty < threeMonthPenalty,
            "invalid value"
        );
        require(
            _sixMonthPenalty > 0 && _sixMonthPenalty < sixMonthPenalty,
            "invalid value"
        );
        require(
            _twelveMonthPenalty > 0 && _twelveMonthPenalty < twelveMonthPenalty,
            "invalid value"
        );
        threeMonthPenalty = _threeMonthPenalty;
        sixMonthPenalty = _sixMonthPenalty;
        twelveMonthPenalty = _twelveMonthPenalty;
        emit RageQuitPenaltiesUpdated(
            threeMonthPenalty,
            sixMonthPenalty,
            twelveMonthPenalty
        );
    }

    /// @dev Admin function to update Flow treasury
    function updateFlowTreasury(address _flowTreasury) external onlyOwner {
        require(_flowTreasury != address(0), "invalid address");
        flowTreasury = _flowTreasury;
    }

    /// @dev Admin function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Admin function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
}