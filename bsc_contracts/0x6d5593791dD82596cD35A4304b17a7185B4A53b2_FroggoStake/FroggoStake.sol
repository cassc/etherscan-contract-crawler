/**
 *Submitted for verification at BscScan.com on 2023-05-14
*/

/**
 *Submitted for verification at BscScan.com on 2022-12-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {

    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

contract FroggoStake is Auth {

    /**
     * @dev Represents a stake made by a user.
     */
    struct StakeState {
		uint256 stakedAmount;
		uint256 rewardDebt;
        uint256 aprIndex;
		uint32 lastChangeTime;
		uint32 lockEndTime;
	}

	/**
     * @dev Informs about the address for the token being used for staking and rewards.
     */
	address public stakingToken;

    /**
     * @dev Tokens the contract owns that are considered as staked by users.
     */
    uint256 public stakedTokens;

    /**
     * @dev Denominator used on all percentage calculations.
     */
    uint16 public constant denominator = 10000;

    /**
     * @dev Fee to pay for the initial stake that is then used for rewards.
     */
    uint16 public depositFee;

    /**
     * @dev Withdrawing before the commited lock time is over costs the user a fee.
     * By making this fee 100%, it's effectively just a time locked staking.
     */
    uint16 public earlyWithdrawFee;

    /**
     * @dev Duration of a stake commitment in seconds.
     * Trying to unstake prior to this time will either be impossible or require to pay a steep fee.
     */
    uint32 public withdrawLockPeriod;

    /**
     * @dev Whether the contract is accepting new stakes or not.
     */
    bool public available;

    /**
     * @dev Track of APR changes as to not to affect users retroactively.
     */
    mapping (uint256 => uint16) internal _aprValues;
    uint256 internal activeAPRIndex;
    uint256 internal lastAPRupdate;

	/**
     * @dev State of user stakes (or lack thereof).
     */
	mapping (address => StakeState) internal stakerDetails;

    event TokenStaked(address indexed user, uint256 amount);
	event TokenUnstaked(address indexed user, uint256 amount, uint256 yield);
	event RewardClaimed(address indexed user, uint256 outAmount);
	event StakingConfigured(uint16 newAPR, uint16 newDepositFee, uint32 newLockPeriod, uint16 newWithdrawFee, bool available);
	event StakingTokenUpdate(address indexed oldToken, address indexed newToken);

    error LockedStake(uint32 unlockTime);
    error NoStakesRequired();
    error DepositFeeTooHigh(uint16 attemptedFee, uint16 maxFee);
    error InvalidWithdrawFee(uint16 attemptedFee, uint16 maxFee);
    error LockTooLong(uint32 attemptedLock, uint32 maxLock);
    error InvalidAPR(uint16 attempted, uint16 min, uint16 max);
    error ZeroStake();
    error StakingUnavailable();
    error NoAvailableYield();
    error StakingActive();
    error NoRewardTokens(uint256 needed, uint256 owned);
    error InvalidWithdraw();
    error GuaranteeTooShort();

    /**
     * @dev To disallow actions that must not be performed while there are existing stakes.
     */
    modifier noStakes {
        if (stakedTokens > 0) {
            revert NoStakesRequired();
        }
		_;
	}

    /**
     * @dev Arbitrary max value for entry fees. Max can depend on use-case and level of security to attain.
     */
	modifier validDepositFee(uint16 fee) {
        uint16 max = denominator / 2;
        if (fee > max) {
            revert DepositFeeTooHigh(fee, max);
        }
		_;
	}

    /**
     * @dev Withdraw fee should be between 0 and 100% of the stake, depending on how locks want to be treated.
     */
    modifier validWithdrawFee(uint16 fee) {
        if (fee > denominator) {
            revert InvalidWithdrawFee(fee, denominator);
        }
		_;
	}

    /**
     * @dev The longest time a stake can be considered locked while yielding in seconds.
     */
	modifier validLockPeriod(uint32 time) {
        if (time > 365 days) {
            revert LockTooLong(time, 365 days);
        }
		_;
	}

    /**
     * @dev An APR is valid when it's more than zero but not too high.
     */
    modifier validAPR(uint16 proposedAPR) {
        uint16 max = type(uint16).max;
        if (proposedAPR == 0) {
            revert InvalidAPR(0, 1, max);
        }
        if (proposedAPR > max) {
            revert InvalidAPR(proposedAPR, 1, max);
        }
        _;
    }

	constructor(address froggoTokenAddress) Auth(msg.sender) {
        // The address for the token used both to add a stake and to receive a reward.
		stakingToken = froggoTokenAddress;

        // Validated initial configuration.
        // 105% APR, no entry fee, 4 weeks lock, 25% penalty, active from start 
		_setStakingConfig(10500, 0, 4 weeks, 2500, true);
	}

    /**
     * @dev Authorised function to change the configuration of the staking.
     */
	function setStakingConfiguration(
		uint16 newAPR, uint16 newDepositFee, uint32 newLockPeriod,
        uint16 newWithdrawFee, bool active
	)
		external authorized validAPR(newAPR) validDepositFee(newDepositFee)
        validWithdrawFee(newWithdrawFee) validLockPeriod(newLockPeriod)
	{
		_setStakingConfig(newAPR, newDepositFee, newLockPeriod, newWithdrawFee, active);
	}

	/**
	 * @dev Internal function for updating full stake configuration.
	 */
	function _setStakingConfig(
		uint16 newAPR, uint16 newDepositFee, uint32 newLockPeriod,
        uint16 newWithdrawFee, bool newAvailability
	) internal {
		_updateAPR(newAPR);
		depositFee = newDepositFee;
		withdrawLockPeriod = newLockPeriod;
        earlyWithdrawFee = newWithdrawFee;
		available = newAvailability;

		emit StakingConfigured(newAPR, newDepositFee, newLockPeriod, newWithdrawFee, newAvailability);
	}

	/**
	 * @dev Sets APR out of the contract specified denominator.
	 */
	function setAPR(uint16 newAPR) external authorized validAPR(newAPR) {
		_updateAPR(newAPR);
		emit StakingConfigured(newAPR, depositFee, withdrawLockPeriod, earlyWithdrawFee, available);
	}

    function _updateAPR(uint16 newAPR) internal {
        ++activeAPRIndex;
        _aprValues[activeAPRIndex] = newAPR;
        lastAPRupdate = block.timestamp;
    }

	/**
	 * @dev Sets deposit fee out of the contract specified denominator.
	 */
	function setDepositFee(uint16 fee) external authorized validDepositFee(fee) {
		depositFee = fee;
        emit StakingConfigured(getCurrentAPR(), fee, withdrawLockPeriod, earlyWithdrawFee, available);
	}

	/**
	 * @dev Set the early withdraw fee out of the contract specified denominator.
	 */
	function setEarlyWithdrawFee(uint16 fee) external authorized validWithdrawFee(fee) {
		earlyWithdrawFee = fee;
        emit StakingConfigured(getCurrentAPR(), depositFee, withdrawLockPeriod, fee, available);
	}

	/**
	 * @dev Allow or disallow new stakes to be done.
	 */
	function setPoolAvailable(bool active) external authorized {
		available = active;
		emit StakingConfigured(getCurrentAPR(), depositFee, withdrawLockPeriod, earlyWithdrawFee, active);
	}

	/**
	 * @dev Early withdraw penalty in seconds.
	 */
	function setEarlyWithdrawLock(uint32 time) external authorized validLockPeriod(time) {
		withdrawLockPeriod = time;
		emit StakingConfigured(getCurrentAPR(), depositFee, time, earlyWithdrawFee, available);
	}

    /**
     * @dev Updates the token for stakes and rewards. Requires for no stakes to be going on.
     */
    function updateStakingToken(address newToken) external authorized noStakes {
		emit StakingTokenUpdate(stakingToken, newToken);
        stakingToken = newToken;
    }

	/**
	 * @dev Check the current unclaimed pending reward for a specific stake.
	 */
	function pendingReward(address account) external view returns (uint256) {
		StakeState storage user = stakerDetails[account];
        return _pendingReward(user);
	}

    function _pendingReward(StakeState storage user) internal view returns (uint256) {
        // Last change time of 0 means there's never been a stake to begin with.
		if (user.lastChangeTime == 0) {
			return 0;
		}

		// Elapsed time since last stake update.
		if (block.timestamp <= user.lastChangeTime) {
			return 0;
		}

        // Check whether APR has changed since stake was done.
        // Take this into consideration while securing past APR.
        uint256 accrued;
        uint256 deltaTime;

        if (user.aprIndex != activeAPRIndex) {
            if (user.lastChangeTime >= lastAPRupdate) {
                deltaTime = block.timestamp - user.lastChangeTime;
                accrued = yieldFromElapsedTime(user.stakedAmount, deltaTime, _aprValues[activeAPRIndex]);
            } else {
                uint256 recentDelta = block.timestamp - lastAPRupdate;
                deltaTime = lastAPRupdate - user.lastChangeTime;
                accrued = yieldFromElapsedTime(user.stakedAmount, recentDelta, _aprValues[activeAPRIndex]);
                accrued += yieldFromElapsedTime(user.stakedAmount, deltaTime, _aprValues[user.aprIndex]);
            }
        } else {
            deltaTime = block.timestamp - user.lastChangeTime;
            accrued = yieldFromElapsedTime(user.stakedAmount, deltaTime, _aprValues[user.aprIndex]);
        }

        // Accrued is what currently is pending, reward debt is stored unclaimed yield value from a update.
		return accrued + user.rewardDebt;
    }

    /**
     * @dev Given amount, time, and APR it will return the yield.
     */
	function yieldFromElapsedTime(uint256 amount, uint256 deltaTime, uint16 appliedAPR) public pure returns (uint256) {
		// No elapsed time, no amount, 0% APR obviously means 0 tokens yielded.
		if (amount == 0 || deltaTime == 0 || appliedAPR == 0) {
			return 0;
		}

		// Calculate the owed reward by seconds elapsed derived from the total reward.
		uint256 annuality = annualYield(amount, appliedAPR);
		if (annuality == 0) {
			return 0;
		}

		return (deltaTime * annuality) / 365 days;
	}

	/**
	 * @dev Given an amount to stake returns a total yield after a year.
	 */
	function annualYield(uint256 amount, uint16 appliedAPR) public pure returns (uint256) {
		if (amount == 0 || appliedAPR == 0) {
			return 0;
		}

		return amount * appliedAPR / denominator;
	}

    /**
     * @dev Add a new stake to the contract. Stakes take the current configuration.
     */
	function stake(uint256 amount) external {
        if (amount == 0) {
            revert ZeroStake();
        }
        if (!available) {
            revert StakingUnavailable();
        }

		StakeState storage user = stakerDetails[msg.sender];
		// Calc unclaimed reward on stake update and set reward timer to now.
        // This allows to increase the stake without needing a claim.
		if (user.lastChangeTime != 0 && user.stakedAmount > 0) {
			user.rewardDebt = _pendingReward(user);
		}
        uint256 stakeAmount = amount;
        // Is deposit fee appliable?
        if (depositFee > 0) {
            uint256 dFee = depositFeeFromAmount(amount);
            unchecked {
                stakeAmount -= dFee;
            }
        }
        unchecked {
		    user.stakedAmount += stakeAmount;
        }

        // First index is 1 and in case of re-stake pending yield has been stored already.
        if (user.aprIndex != activeAPRIndex) {
            user.aprIndex = activeAPRIndex;
        }

        // For a first stake we get the lock period from current configuration.
		uint32 rnow = uint32(block.timestamp);
		user.lastChangeTime = rnow;
        if (user.lockEndTime == 0) {
            user.lockEndTime = rnow + withdrawLockPeriod;
        }

        // Keeping track of overall staked tokens.
        unchecked {
            stakedTokens += stakeAmount;
        }

        // Transfer tokens from user to the contract.
        IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);

		emit TokenStaked(msg.sender, stakeAmount);
	}

    /**
     * @dev Calculates fee to pay to deposit a new stake under the current configuration.
     */
	function depositFeeFromAmount(uint256 amount) public view returns (uint256) {
		if (depositFee == 0) {
			return 0;
		}
		return amount * depositFee / denominator;
	}

    /**
     * @dev Claim your yield and unstake all your tokens.
     */
	function unstake() external {
		_unstake(msg.sender, false);
	}

    /**
     * @dev In a case where the contract will not be able to provide for the yield, unstake tokens forfeiting yield.
     */
    function emergencyUnstake() external {
        _unstake(msg.sender, true);
    }

    /**
	 * @dev Allows an authorised account to finalise a staking that is not locked while staking is finished.
	 */
	function forceUnstake(address staker) external authorized {
		// Staking must be currently not available to force unstakes.
        if (available) {
            revert StakingActive();
        }

		// The stake must have finished its lock time or have no withdraw fee.
        StakeState storage user = stakerDetails[staker];
        if (earlyWithdrawFee > 0 && user.lockEndTime > block.timestamp) {
            revert LockedStake(stakerDetails[staker].lockEndTime);
        }

		// Run their claim and unstake.
        // Admins cannot force unstake with forfeit of rewards.
		_unstake(staker, false);
	}

    /**
     * @dev Removes an entire stake by a user.
     */
	function _unstake(address staker, bool forfeit) internal {
		StakeState storage user = stakerDetails[staker];
		uint256 totalStakedTokens = user.stakedAmount;
        if (totalStakedTokens == 0) {
            revert ZeroStake();
        }
        uint256 yield;
        uint256 unstakeAmount = totalStakedTokens;
        bool isEarlyWithdraw = earlyWithdrawFee > 0 && block.timestamp < user.lockEndTime;

		// Update user staking status.
		// When unstaking is done, claim is automatically done.
        // Early withdraws lose the yield.
        if (forfeit || isEarlyWithdraw) {
            user.lastChangeTime = uint32(block.timestamp);
            user.rewardDebt = 0;
        } else {
            yield = _claim(user);
        }
		user.stakedAmount = 0;

        // Early withdraw fee.
        if (isEarlyWithdraw) {
            // If withdraw fee is set at 100%, it means the stake is fully locked.
            if (earlyWithdrawFee == denominator) {
                revert LockedStake(user.lockEndTime);
            }
            uint256 fee = totalStakedTokens * earlyWithdrawFee / denominator;
            unchecked {
                unstakeAmount -= fee;
            }
        }
        user.lockEndTime = 0;

        // Return token to staker and update staking values.
		IERC20(stakingToken).transfer(staker, unstakeAmount + yield);
        unchecked {
		    stakedTokens -= totalStakedTokens;
        }

		emit TokenUnstaked(staker, unstakeAmount, yield);
	}

    /**
     * @dev Claim your pending yield, if any.
     */
	function claim() external {
        StakeState storage user = stakerDetails[msg.sender];
        if (earlyWithdrawFee > 0 && block.timestamp < user.lockEndTime) {
            revert LockedStake(user.lockEndTime);
        }
		uint256 outAmount = _claim(user);
        if (outAmount == 0) {
            revert NoAvailableYield();
        }
        if (user.aprIndex != activeAPRIndex) {
            user.aprIndex = activeAPRIndex;
        }
        IERC20(stakingToken).transfer(msg.sender, outAmount);
        emit RewardClaimed(msg.sender, outAmount);
	}

    /**
     * @dev Returns amount to be sent to user after calculating and updating yield.
     */
	function _claim(StakeState storage user) internal returns (uint256) {
		uint256 outAmount = _pendingReward(user);
		if (outAmount > 0) {
			// To protect user funds, reward tokens must not come from their staked tokens.
            // Claim transactions will all fail.
            // Non emergency unstake transactions as well, so it's up to the user to decide either:
            // Wait for availability of reward tokens.
            // Recover stake and forfeit any yield.
			uint256 availableReward = availableRewardTokens();
            if (availableReward < outAmount) {
                revert NoRewardTokens(outAmount, availableReward);
            }
			user.rewardDebt = 0;
			user.lastChangeTime = uint32(block.timestamp);
		}

        return outAmount;
	}

	/**
	 * @dev Checks whether there's a stake withdraw fee or not.
	 */
	function canWithdrawTokensNoFee(address user) external view returns (bool) {
		if (stakerDetails[user].lastChangeTime == 0) {
			return false;
		}

		return block.timestamp > stakerDetails[user].lockEndTime;
	}

	/**
	 * @dev Rescue non staking tokens sent to this contract by accident.
	 */
	function rescueToken(address t) external authorized {
        if (t == stakingToken) {
            revert InvalidWithdraw();
        }
        IERC20 rescuee = IERC20(t);
		uint256 balance = rescuee.balanceOf(address(this));
		rescuee.transfer(msg.sender, balance);
	}

    function rescuePrizeTokens() external authorized {
        uint256 prize = availableRewardTokens();
        if (prize > 0) {
            IERC20(stakingToken).transfer(msg.sender, prize);
        }
	}

	function getStake(address staker) public view returns (StakeState memory) {
		return stakerDetails[staker];
	}

	function getOwnStake() external view returns (StakeState memory) {
		return getStake(msg.sender);
	}

	function getOwnPendingReward() external view returns (uint256) {
        StakeState storage user = stakerDetails[msg.sender];
		return _pendingReward(user);
	}

    function getCurrentAPR() public view returns (uint16) {
        return _aprValues[activeAPRIndex];
    }

	/**
	 * @dev Given a theroetical stake, returns the unstake return amount, deposit fee paid, and yield on a year under current configuration.
	 */
	function simulateYearStake(uint256 amount) external view returns (uint256 unstakeAmount, uint256 stakeFee, uint256 yield) {
		if (amount == 0) {
			return (0, 0, 0);
		}
        uint16 currApr = getCurrentAPR();
		uint256 fee = depositFeeFromAmount(amount);
		uint256 actual = amount - fee;
		uint256 y = annualYield(actual, currApr);

		return (actual, fee, y);
	}

	/**
	 * @dev Given an amount and a duration, returns unstake amount, fees paid, and yield.
	 */
	function simulateStake(uint256 amount, uint32 duration) external view returns (uint256 unstakeAmount, uint256 stakeFee, uint256 yield) {
		if (amount == 0 || duration == 0) {
			return (0, 0, 0);
		}
        uint16 currApr = getCurrentAPR();
		uint256 fee = depositFeeFromAmount(amount);
		uint256 actual = amount - fee;
		uint256 y = yieldFromElapsedTime(actual, duration, currApr);
		if (earlyWithdrawFee > 0 && duration <= withdrawLockPeriod) {
            uint256 withdrawFee = amount * earlyWithdrawFee / denominator;
            actual -= withdrawFee;
        }

		return (actual, fee, y);
	}

    /**
     * @dev How many of the tokens owned by the contract can be used for yield rewards.
     */
    function availableRewardTokens() public view returns (uint256) {
        uint256 balance = IERC20(stakingToken).balanceOf(address(this));
        if (stakedTokens >= balance) {
            return 0;
        }
        return balance - stakedTokens;
    }

    function getLastAPRUpdate() external view returns (uint256) {
        return lastAPRupdate;
    }

    function countAPRUpdates() external view returns (uint256) {
        if (activeAPRIndex == 0) {
            return 0;
        }
        return activeAPRIndex - 1;
    }
}