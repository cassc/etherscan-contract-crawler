/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Staking system for BBQ token at 0x098a6200A49cA3E4CB8251529939F9A6DAC4397A

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

abstract contract Ownership {

	address public owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	error NotOwner();

	modifier onlyOwner {
		if (msg.sender != owner) {
			revert NotOwner();
		}
		_;
	}

	constructor(address owner_) {
		owner = owner_;
	}

	function _renounceOwnership() internal virtual {
		owner = address(0);
		emit OwnershipTransferred(owner, address(0));
	}

	function renounceOwnership() external onlyOwner {
		_renounceOwnership();
	}
}

contract BBQStaking is Ownership {

    struct StakeState {
		uint256 stakedAmount;
		uint256 rewardDebt;
        uint256 aprIndex;
		uint32 lastChangeTime;
		uint32 lockEndTime;
	}

	address public stakingToken;
    uint256 public stakedTokens;
    uint16 public constant denominator = 100_00;
    uint16 public apr;
    uint16 public depositFee;
    uint16 public earlyWithdrawFee;
    uint32 public withdrawLockPeriod;
    bool public available;

    mapping (uint256 => uint16) internal _aprValues;
    uint256 internal activeAPRIndex;
    uint256 internal lastAPRupdate;
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
    error InvalidAPR(uint16 attemptedAPR, uint16 minAPR, uint16 maxAPR);
    error ZeroStake();
    error StakingUnavailable();
    error NoAvailableYield();
    error StakingActive();
    error NoRewardTokens(uint256 needed, uint256 owned);
    error InvalidWithdraw();
    error GuaranteeTooShort();

    modifier noStakes {
        if (stakedTokens > 0) {
            revert NoStakesRequired();
        }
		_;
	}

	modifier validDepositFee(uint16 fee) {
        uint16 max = denominator / 2;
        if (fee > max) {
            revert DepositFeeTooHigh(fee, max);
        }
		_;
	}

    modifier validWithdrawFee(uint16 fee) {
        if (fee > denominator) {
            revert InvalidWithdrawFee(fee, denominator);
        }
		_;
	}

	modifier validLockPeriod(uint32 time) {
        if (time > 365 days) {
            revert LockTooLong(time, 365 days);
        }
		_;
	}

    modifier validAPR(uint16 proposedAPR) {
        uint16 reasonableMax = denominator * 3;

        if (proposedAPR == 0) {
            revert InvalidAPR(0, 1, reasonableMax);
        }

        if (proposedAPR > reasonableMax) {
            revert InvalidAPR(proposedAPR, 1, reasonableMax);
        }
        _;
    }

	constructor() Ownership(msg.sender) {
		stakingToken = 0x098a6200A49cA3E4CB8251529939F9A6DAC4397A;
		_setStakingConfig(200_00, 0, 12 hours, 30_00, false);
	}

	function setStakingConfiguration(
		uint16 newAPR, uint16 newDepositFee, uint32 newLockPeriod,
        uint16 newWithdrawFee, bool active
	)
		external onlyOwner validAPR(newAPR) validDepositFee(newDepositFee)
        validWithdrawFee(newWithdrawFee) validLockPeriod(newLockPeriod)
	{
		_setStakingConfig(newAPR, newDepositFee, newLockPeriod, newWithdrawFee, active);
	}

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

	function setAPR(uint16 newAPR) external onlyOwner validAPR(apr) {
		_updateAPR(newAPR);
		emit StakingConfigured(newAPR, depositFee, withdrawLockPeriod, earlyWithdrawFee, available);
	}

    function _updateAPR(uint16 newAPR) internal {
        ++activeAPRIndex;
        _aprValues[activeAPRIndex] = newAPR;
        lastAPRupdate = block.timestamp;
    }

	function setDepositFee(uint16 fee) external onlyOwner validDepositFee(fee) {
		depositFee = fee;
        emit StakingConfigured(apr, fee, withdrawLockPeriod, earlyWithdrawFee, available);
	}

	function setEarlyWithdrawFee(uint16 fee) external onlyOwner validWithdrawFee(fee) {
		earlyWithdrawFee = fee;
        emit StakingConfigured(apr, depositFee, withdrawLockPeriod, fee, available);
	}

	function setPoolAvailable(bool active) external onlyOwner {
		available = active;
		emit StakingConfigured(apr, depositFee, withdrawLockPeriod, earlyWithdrawFee, active);
	}

	function setEarlyWithdrawLock(uint32 time) external onlyOwner validLockPeriod(time) {
		withdrawLockPeriod = time;
		emit StakingConfigured(apr, depositFee, time, earlyWithdrawFee, available);
	}

    function updateStakingToken(address newToken) external onlyOwner noStakes {
		emit StakingTokenUpdate(stakingToken, newToken);
        stakingToken = newToken;
    }

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

	function annualYield(uint256 amount, uint16 appliedAPR) public pure returns (uint256) {
		if (amount == 0 || appliedAPR == 0) {
			return 0;
		}

		return amount * appliedAPR / denominator;
	}

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

	function depositFeeFromAmount(uint256 amount) public view returns (uint256) {
		if (depositFee == 0) {
			return 0;
		}
		return amount * depositFee / denominator;
	}

	function unstake() external {
		_unstake(msg.sender, false);
	}

    function emergencyUnstake() external {
        _unstake(msg.sender, true);
    }

	function forceUnstake(address staker) external onlyOwner {
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

	function _unstake(address staker, bool forfeit) internal {
		StakeState storage user = stakerDetails[staker];
		uint256 totalStakedTokens = user.stakedAmount;
        if (totalStakedTokens == 0) {
            revert ZeroStake();
        }
        uint256 yield;
        uint256 unstakeAmount = totalStakedTokens;

		// Update user staking status.
		// When unstaking is done, claim is automatically done.
        if (forfeit) {
            user.lastChangeTime = uint32(block.timestamp);
            user.rewardDebt = 0;
        } else {
            yield = _claim(user);
        }
		user.stakedAmount = 0;

        // Check for early withdraw fee.
        if (earlyWithdrawFee > 0 && block.timestamp < user.lockEndTime) {
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

	function claim() external {
        StakeState storage user = stakerDetails[msg.sender];
		uint256 outAmount = _claim(user);
        if (outAmount == 0) {
            revert NoAvailableYield();
        }
        IERC20(stakingToken).transfer(msg.sender, outAmount);
        emit RewardClaimed(msg.sender, outAmount);
	}

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

	function canWithdrawTokensNoFee(address user) external view returns (bool) {
		if (stakerDetails[user].lastChangeTime == 0) {
			return false;
		}

		return block.timestamp > stakerDetails[user].lockEndTime;
	}

	function rescueToken(address t, address receiver) external onlyOwner {
        if (t == stakingToken) {
            revert InvalidWithdraw();
        }
        IERC20 rescuee = IERC20(t);
		uint256 balance = rescuee.balanceOf(address(this));
		rescuee.transfer(receiver, balance);
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

    function getAPRUpdateCount() external view returns (uint256) {
        if (activeAPRIndex == 0) {
            return 0;
        }
        return activeAPRIndex - 1;
    }
}