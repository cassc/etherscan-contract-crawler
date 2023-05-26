// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PoolLP is Ownable {
	struct UserInfo {
		uint amount;
		uint rewardDebt;
		uint timestamp;
	}

	IERC20 public immutable TOKEN;
	IERC20 public immutable LP;
	address public STAKING;

	uint private constant PRECISION = 1e12;
	uint public constant START_AMOUNT = 5_000_000 ether;
	uint public constant EPOCH_AMOUNT = 3_600_000 ether;
	uint public constant EPOCH_DURATION = 1 days;
	uint public constant MAX_REWARDS = 400_000_000 ether;
	uint public totalStaked;
	uint public totalRewards;
	uint public tokenPerSecond;
	uint public epoch;
	uint public epochEndTime;
	uint public lastRewardTime;
	uint public START_TIME;

	uint public accTokenPerShare;
	mapping(address => UserInfo) public userInfo;

	constructor(IERC20 token, IERC20 lp) {
		TOKEN = token;
		LP = lp;
	}

	function init(address staking) external onlyOwner {
		require(STAKING == address(0), "Already initialized");
		STAKING = staking;
	}

	function start() external {
		require(msg.sender == STAKING, "Only Staking");
		START_TIME = block.timestamp;
		lastRewardTime = block.timestamp;
		epochEndTime = block.timestamp + EPOCH_DURATION;
		tokenPerSecond = START_AMOUNT / EPOCH_DURATION;
	}

	function stake(uint amount) external {
		_updatePool();

		uint newAmount = userInfo[msg.sender].amount + amount;
		userInfo[msg.sender] = UserInfo({
			amount: newAmount,
			rewardDebt: newAmount * accTokenPerShare / PRECISION,
			timestamp: block.timestamp
		});

		totalStaked += amount;
		LP.transferFrom(msg.sender, address(this), amount);
	}
	
	function unstake(uint amount) external {
		_updatePool();

		uint newAmount = userInfo[msg.sender].amount - amount;
		userInfo[msg.sender] = UserInfo({
			amount: newAmount,
			rewardDebt: newAmount * accTokenPerShare / PRECISION,
			timestamp: block.timestamp
		});

		totalStaked -= amount;
		LP.transfer(msg.sender, amount);
	}

	function claim() external {
		_updatePool();

		UserInfo storage user = userInfo[msg.sender];
		require(block.timestamp - user.timestamp > 1 days, "Cannot claim yet");

		uint pending = user.amount * accTokenPerShare / PRECISION - user.rewardDebt;
		user.rewardDebt =  user.amount * accTokenPerShare / PRECISION;
		user.timestamp =  block.timestamp;
		TOKEN.transfer(msg.sender, pending);
	}

	function emergencyUnstake() external {
		uint amount = userInfo[msg.sender].amount;
		userInfo[msg.sender] = UserInfo(0, 0, 0);
		totalStaked -= amount;
		LP.transfer(msg.sender, amount);
	}

	function updatePool() external {
		_updatePool();
	}
	
	function recover() external onlyOwner {
		require(block.timestamp > START_TIME + 30 days);
		TOKEN.transfer(msg.sender, TOKEN.balanceOf(address(this)));
	}

	function getPending(address who) external view returns (uint) {
		UserInfo storage user = userInfo[who];
		
		uint accTokenPerShareCached = accTokenPerShare;
		uint stakedLP = totalStaked;

		if (stakedLP == 0) return 0;

		uint multiplier = block.timestamp - lastRewardTime;
		uint rewards = multiplier * tokenPerSecond;
		
		if (totalRewards + rewards > MAX_REWARDS) {
			rewards = MAX_REWARDS - totalRewards;
		}

		accTokenPerShareCached += rewards * PRECISION / stakedLP;

		return user.amount * accTokenPerShareCached / PRECISION - user.rewardDebt;
	}

	function _updatePool() internal {
		if (totalRewards == MAX_REWARDS) return;
	
		uint256 stakedLP = totalStaked;
		if (stakedLP == 0) {
			require(lastRewardTime != 0, "Not started yet");
			lastRewardTime = block.timestamp;
			return;
		}

		if (block.timestamp > epochEndTime) {
			_updateAcc(epochEndTime, stakedLP);

			epoch += 1;
			epochEndTime = block.timestamp + EPOCH_DURATION;
			tokenPerSecond = (START_AMOUNT + EPOCH_AMOUNT * epoch) / EPOCH_DURATION;
		}

		_updateAcc(block.timestamp, stakedLP);
	}

	function _updateAcc(uint timestamp, uint stakedLP) internal {
		uint multiplier = timestamp - lastRewardTime;
		uint rewards = multiplier * tokenPerSecond;
		
		if (totalRewards + rewards > MAX_REWARDS) {
			rewards = MAX_REWARDS - totalRewards;
			totalRewards = MAX_REWARDS;
		} else {
			totalRewards += rewards;
		}

		accTokenPerShare += rewards * PRECISION / stakedLP;
		lastRewardTime = timestamp;
	}
}