// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "../libraries/SafeMath.sol";
import "../libraries/TransferHelper.sol";
import "../modules/Configable.sol";
import "../modules/ConfigNames.sol";

interface IERC20 {
	function approve(address spender, uint256 value) external returns (bool);

	function balanceOf(address owner) external view returns (uint256);
}

contract BaseMintField is Configable {
	using SafeMath for uint256;

	uint256 public mintCumulation;

	uint256 public totalLendProductivity;
	uint256 public totalBorrowProducitivity;
	uint256 public accAmountPerLend;
	uint256 public accAmountPerBorrow;

	uint256 public totalBorrowSupply;
	uint256 public totalLendSupply;

	struct UserInfo {
		uint256 amount; // How many tokens the user has provided.
		uint256 rewardDebt; // Reward debt.
		uint256 rewardEarn; // Reward earn and not minted
		uint256 index;
	}

	mapping(address => UserInfo) public lenders;
	mapping(address => UserInfo) public borrowers;

	uint256 public totalShare;
	uint256 public mintedShare;
	event BorrowPowerChange(uint256 oldValue, uint256 newValue);
	event InterestRatePerBlockChanged(uint256 oldValue, uint256 newValue);
	event BorrowerProductivityIncreased(address indexed user, uint256 value);
	event BorrowerProductivityDecreased(address indexed user, uint256 value);
	event LenderProductivityIncreased(address indexed user, uint256 value);
	event LenderProductivityDecreased(address indexed user, uint256 value);
	event MintLender(address indexed user, uint256 userAmount);
	event MintBorrower(address indexed user, uint256 userAmount); // Update reward variables of the given pool to be up-to-date.

	function _update() internal virtual {
		uint256 reward = _currentReward();
		totalShare += reward;
		if (totalLendProductivity.add(totalBorrowProducitivity) == 0 || reward == 0) {
			return;
		}

		uint256 borrowReward =
			reward.mul(IConfig(config).getPoolValue(address(this), ConfigNames.POOL_MINT_BORROW_PERCENT)).div(10000);
		uint256 lendReward = reward.sub(borrowReward);

		if (totalLendProductivity != 0 && lendReward > 0) {
			totalLendSupply = totalLendSupply.add(lendReward);
			accAmountPerLend = accAmountPerLend.add(lendReward.mul(1e12).div(totalLendProductivity));
		}

		if (totalBorrowProducitivity != 0 && borrowReward > 0) {
			totalBorrowSupply = totalBorrowSupply.add(borrowReward);
			accAmountPerBorrow = accAmountPerBorrow.add(borrowReward.mul(1e12).div(totalBorrowProducitivity));
		}
	}

	function _currentReward() internal view virtual returns (uint256) {
		return mintedShare.add(IERC20(IConfig(config).token()).balanceOf(address(this))).sub(totalShare);
	}

	// Audit borrowers's reward to be up-to-date
	function _auditBorrower(address user) internal {
		UserInfo storage userInfo = borrowers[user];
		if (userInfo.amount > 0) {
			uint256 pending = userInfo.amount.mul(accAmountPerBorrow).div(1e12).sub(userInfo.rewardDebt);
			userInfo.rewardEarn = userInfo.rewardEarn.add(pending);
			mintCumulation = mintCumulation.add(pending);
			userInfo.rewardDebt = userInfo.amount.mul(accAmountPerBorrow).div(1e12);
		}
	}

	// Audit lender's reward to be up-to-date
	function _auditLender(address user) internal {
		UserInfo storage userInfo = lenders[user];
		if (userInfo.amount > 0) {
			uint256 pending = userInfo.amount.mul(accAmountPerLend).div(1e12).sub(userInfo.rewardDebt);
			userInfo.rewardEarn = userInfo.rewardEarn.add(pending);
			mintCumulation = mintCumulation.add(pending);
			userInfo.rewardDebt = userInfo.amount.mul(accAmountPerLend).div(1e12);
		}
	}

	function _increaseBorrowerProductivity(address user, uint256 value) internal returns (bool) {
		require(value > 0, "PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO");
		UserInfo storage userInfo = borrowers[user];
		_update();
		_auditBorrower(user);
		totalBorrowProducitivity = totalBorrowProducitivity.add(value);
		userInfo.amount = userInfo.amount.add(value);
		userInfo.rewardDebt = userInfo.amount.mul(accAmountPerBorrow).div(1e12);
		emit BorrowerProductivityIncreased(user, value);
		return true;
	}

	function _decreaseBorrowerProductivity(address user, uint256 value) internal returns (bool) {
		require(value > 0, "INSUFFICIENT_PRODUCTIVITY");

		UserInfo storage userInfo = borrowers[user];
		require(userInfo.amount >= value, "FORBIDDEN");
		_update();
		_auditBorrower(user);

		userInfo.amount = userInfo.amount.sub(value);
		userInfo.rewardDebt = userInfo.amount.mul(accAmountPerBorrow).div(1e12);
		totalBorrowProducitivity = totalBorrowProducitivity.sub(value);
		emit BorrowerProductivityDecreased(user, value);
		return true;
	}

	function _increaseLenderProductivity(address user, uint256 value) internal returns (bool) {
		require(value > 0, "PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO");
		UserInfo storage userInfo = lenders[user];
		_update();
		_auditLender(user);
		totalLendProductivity = totalLendProductivity.add(value);
		userInfo.amount = userInfo.amount.add(value);
		userInfo.rewardDebt = userInfo.amount.mul(accAmountPerLend).div(1e12);
		emit LenderProductivityIncreased(user, value);
		return true;
	}

	// External function call
	// This function will decreases user's productivity by value, and updates the global productivity
	// it will record which block this is happenning and accumulates the area of (productivity * time)
	function _decreaseLenderProductivity(address user, uint256 value) internal returns (bool) {
		require(value > 0, "INSUFFICIENT_PRODUCTIVITY");

		UserInfo storage userInfo = lenders[user];
		require(userInfo.amount >= value, "FORBIDDEN");
		_update();
		_auditLender(user);

		userInfo.amount = userInfo.amount.sub(value);
		userInfo.rewardDebt = userInfo.amount.mul(accAmountPerLend).div(1e12);
		totalLendProductivity = totalLendProductivity.sub(value);
		emit LenderProductivityDecreased(user, value);
		return true;
	}

	function takeBorrowWithAddress(address user) public view returns (uint256) {
		UserInfo storage userInfo = borrowers[user];
		uint256 _accAmountPerBorrow = accAmountPerBorrow;
		if (totalBorrowProducitivity != 0) {
			uint256 reward = _currentReward();
			uint256 borrowReward =
				reward.mul(IConfig(config).getPoolValue(address(this), ConfigNames.POOL_MINT_BORROW_PERCENT)).div(10000);

			_accAmountPerBorrow = accAmountPerBorrow.add(borrowReward.mul(1e12).div(totalBorrowProducitivity));
		}

		return userInfo.amount.mul(_accAmountPerBorrow).div(1e12).sub(userInfo.rewardDebt).add(userInfo.rewardEarn);
	}

	function takeLendWithAddress(address user) public view returns (uint256) {
		UserInfo storage userInfo = lenders[user];
		uint256 _accAmountPerLend = accAmountPerLend;
		if (totalLendProductivity != 0) {
			uint256 reward = _currentReward();
			uint256 lendReward =
				reward.sub(reward.mul(IConfig(config).getPoolValue(address(this), ConfigNames.POOL_MINT_BORROW_PERCENT)).div(10000));
			_accAmountPerLend = accAmountPerLend.add(lendReward.mul(1e12).div(totalLendProductivity));
		}
		return userInfo.amount.mul(_accAmountPerLend).div(1e12).sub(userInfo.rewardDebt).add(userInfo.rewardEarn);
	}

	function takeBorrowWithBlock() external view returns (uint256, uint256) {
		uint256 earn = takeBorrowWithAddress(msg.sender);
		return (earn, block.number);
	}

	function takeLendWithBlock() external view returns (uint256, uint256) {
		uint256 earn = takeLendWithAddress(msg.sender);
		return (earn, block.number);
	}

	function takeAll() public view returns (uint256) {
		return takeBorrowWithAddress(msg.sender).add(takeLendWithAddress(msg.sender));
	}

	function takeAllWithBlock() external view returns (uint256, uint256) {
		return (takeAll(), block.number);
	}

	function _mintBorrower() internal returns (uint256) {
		_update();
		_auditBorrower(msg.sender);
		if (borrowers[msg.sender].rewardEarn > 0) {
			uint256 amount = borrowers[msg.sender].rewardEarn;
			_mintDistribution(msg.sender, amount);
			borrowers[msg.sender].rewardEarn = 0;
			emit MintBorrower(msg.sender, amount);
			return amount;
		}
	}

	function _mintLender() internal returns (uint256) {
		_update();
		_auditLender(msg.sender);
		if (lenders[msg.sender].rewardEarn > 0) {
			uint256 amount = lenders[msg.sender].rewardEarn;
			_mintDistribution(msg.sender, amount);
			lenders[msg.sender].rewardEarn = 0;
			emit MintLender(msg.sender, amount);
			return amount;
		}
	}

	// Returns how many productivity a user has and global has.
	function getBorrowerProductivity(address user) external view returns (uint256, uint256) {
		return (borrowers[user].amount, totalBorrowProducitivity);
	}

	function getLenderProductivity(address user) external view returns (uint256, uint256) {
		return (lenders[user].amount, totalLendProductivity);
	}

	// Returns the current gorss product rate.
	function interestsPerBlock() external view returns (uint256, uint256) {
		return (accAmountPerBorrow, accAmountPerLend);
	}

	function _mintDistribution(address user, uint256 amount) internal {
		if (amount > 0) {
			mintedShare += amount;
			TransferHelper.safeTransfer(IConfig(config).token(), user, amount);
		}
	}
}