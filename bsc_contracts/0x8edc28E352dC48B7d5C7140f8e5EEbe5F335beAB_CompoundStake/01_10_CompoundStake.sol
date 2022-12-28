// SPDX-License-Identifier: Diversity
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


interface IDividendToken {
   
    function removeStaker(address _staker) external;
    function addStaker(address _staker, uint256 _amount) external;
}

contract CompoundStake is Ownable {
	using EnumerableSet for EnumerableSet.AddressSet;
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	uint256 public constant ACC_PRECISION = 1e12;

	struct UserInfo {
		uint256 amount;
		uint256 rewardDebt;
		uint256 rewardAmount;
		uint256 lastStakeTime;
	}

	// Info of each pool.
	struct PoolInfo {
		IERC20 poolToken;
		uint256 allocPoint;
		uint256 lastRewardTime;
		uint256 accRewardPerShare;
		uint256 amount;
		uint256 lockDuration;
	}

	ERC20 public rewardToken;
	IDividendToken public dividendToken;
	uint256 public tokenPerSecond;
	uint256 public startTime;
	uint256 public stakeFee;
	uint256 public withdrawFee;
	address public rewardAddress;
	uint256 public constant taxFee = 10000;

	PoolInfo[] public poolInfo;
	mapping(uint256 => mapping(address => UserInfo)) public userInfo;
	mapping(uint256 => EnumerableSet.AddressSet) private poolUsers;

	uint256 public totalAllocPoint = 0;

	event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
	event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
	event Harvest(address indexed user, uint256 indexed pid, uint256 amount);

	constructor(
		address _rewardTokenAddress,
		uint256 _rewardPerBlock,
		uint256 _startTime,
		uint256 _stakeFee,
		uint256 _withdrawFee,
		address _rewardAddress
	) {
		rewardToken = ERC20(_rewardTokenAddress);
		stakeFee = _stakeFee;
		withdrawFee = _withdrawFee;
		tokenPerSecond = _rewardPerBlock;
		startTime = _startTime;
		rewardAddress = _rewardAddress;
		dividendToken = IDividendToken(_rewardTokenAddress);
	}

	modifier verifyPoolId(uint256 _pid) {
		require(_pid < poolInfo.length, "Pool is not exist");
		_;
	}

	function poolLength() external view returns (uint256) {
		return poolInfo.length;
	}

	function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
		return _to.sub(_from);
	}

	function getUserStakeBalance(uint256 _pid, address _user) external view returns (uint256) {
		return userInfo[_pid][_user].amount;
	}

	// View function to see pending BSLs on frontend.
	function getRewardAmount(uint256 _pid, address _user) external view verifyPoolId(_pid) returns (uint256) {
		PoolInfo memory pool = poolInfo[_pid];
		UserInfo memory user = userInfo[_pid][_user];
		uint256 accRewardPerShare = pool.accRewardPerShare;
		uint256 lpSupply = pool.amount;
		if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
			uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
			uint256 rewardAmount = multiplier.mul(tokenPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
			accRewardPerShare = accRewardPerShare.add(rewardAmount.mul(ACC_PRECISION).div(lpSupply));
		}

		uint256 pendingAmount = user.amount.mul(accRewardPerShare).div(ACC_PRECISION).sub(user.rewardDebt);
		return user.rewardAmount.add(pendingAmount);
	}

	// Update reward variables for all pools. Be careful of gas spending!
	function massUpdatePools() public {
		for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
			updatePool(pid);
		}
	}

	// Update reward variables of the given pool to be up-to-date.
	function updatePool(uint256 _pid) public verifyPoolId(_pid) {
		PoolInfo storage pool = poolInfo[_pid];
		if (block.timestamp <= pool.lastRewardTime) {
			return;
		}
		uint256 lpSupply = pool.amount;
		if (lpSupply == 0) {
			pool.lastRewardTime = block.timestamp;
			return;
		}
		uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
		uint256 rewardAmount = multiplier.mul(tokenPerSecond).mul(pool.allocPoint).div(totalAllocPoint);

		pool.accRewardPerShare = pool.accRewardPerShare.add(rewardAmount.mul(ACC_PRECISION).div(lpSupply));
		pool.lastRewardTime = block.timestamp;
	}

	function stake(uint256 _pid, uint256 _amount) external verifyPoolId(_pid)  {
		require(_amount > 0, "amount must be greater than 0");
		updatePool(_pid);

		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];

		// Update last reward
		uint256 pendingAmount = user.amount.mul(pool.accRewardPerShare).div(ACC_PRECISION).sub(user.rewardDebt);
		if (pendingAmount > 0) {
			user.rewardAmount = user.rewardAmount.add(pendingAmount);
		}

		// Statistical
		if (user.amount == 0) {
			poolUsers[_pid].add(msg.sender);
		}

		uint256 amountStake = _amount;
		if(stakeFee > 0){
			uint256 feeStake = amountStake.mul(stakeFee).div(taxFee);
			amountStake = amountStake.sub(feeStake);
			pool.poolToken.safeTransferFrom(address(msg.sender), rewardAddress, feeStake);
		}

		uint256 amountAfter = user.amount.add(amountStake);

		
		
		// Add LP
		pool.poolToken.safeTransferFrom(address(msg.sender), address(this), amountStake);
		pool.amount = pool.amount.add(amountStake);
		user.amount = user.amount.add(amountStake);
		user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(ACC_PRECISION);
		user.lastStakeTime = block.timestamp;
		try dividendToken.addStaker(address(msg.sender), amountAfter) {} catch {}
		emit Deposit(msg.sender, _pid, amountStake);
	}

	function unstake(uint256 _pid) public verifyPoolId(_pid) {
		UserInfo storage user = userInfo[_pid][msg.sender];
		PoolInfo storage pool = poolInfo[_pid];

		uint256 _amount = user.amount;
		require(_amount > 0, "amount is zero");
		//require(user.lastStakeTime.add(pool.lockDuration) < block.timestamp, "Under locked");
		

		updatePool(_pid);
		uint256 pendingAmount = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
		if (pendingAmount > 0) {
			user.rewardAmount = user.rewardAmount.add(pendingAmount);
		}

		uint256 amountStake = _amount;
		if(user.lastStakeTime.add(pool.lockDuration) >= block.timestamp){
			uint256 feeUnStake = amountStake.mul(withdrawFee).div(taxFee);
			amountStake = amountStake.sub(feeUnStake);
			pool.poolToken.safeTransfer(rewardAddress, feeUnStake);
		}

		user.lastStakeTime = block.timestamp;

		

		pool.poolToken.safeTransfer(msg.sender, amountStake);
		user.amount = 0;
		pool.amount = pool.amount.sub(_amount);
		user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(ACC_PRECISION);

		poolUsers[_pid].remove(msg.sender);
		try dividendToken.removeStaker(address(msg.sender)) {} catch {}
		
		emit Withdraw(msg.sender, _pid, _amount);
	}

	function harvest(uint256 _pid) external verifyPoolId(_pid) returns (uint256) {
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];

		updatePool(_pid);

		uint256 pendingAmount = user.amount.mul(pool.accRewardPerShare).div(ACC_PRECISION).sub(user.rewardDebt);
		pendingAmount = user.rewardAmount.add(pendingAmount);
		if (pendingAmount > 0) {
			rewardToken.transfer(msg.sender, pendingAmount);
		}
		user.rewardAmount = 0;
		user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(ACC_PRECISION);
		emit Harvest(msg.sender, _pid, pendingAmount);
		return pendingAmount;
	}

	// getters
	function getPoolUserLength(uint256 _pid) external view returns (uint256) {
		return poolUsers[_pid].length();
	}

	function getPoolUsers(uint256 _pid) external view returns (address[] memory) {
		return poolUsers[_pid].values();
	}

	function getPoolUserStakes(uint256 _pid) external view returns (address[] memory, uint256[] memory) {
		uint256 _len = poolUsers[_pid].length();
		uint256[] memory stakeAmount = new uint256[](_len);
		address[] memory users = poolUsers[_pid].values();
		for (uint256 index = 0; index < _len; index++) {
			stakeAmount[index] = userInfo[_pid][poolUsers[_pid].at(index)].amount;
		}
		return (users, stakeAmount);
	}

	function getSubPoolUsers(
		uint256 _pid,
		uint256 _from,
		uint256 _length
	) external view returns (address[] memory) {
		uint256 _poolUserLength = poolUsers[_pid].length();
		if (_from.add(_length) > _poolUserLength) {
			_length = _poolUserLength.sub(_from);
		}
		address[] memory results = new address[](_length);
		for (uint256 index = 0; index < _length; index++) {
			results[index] = poolUsers[_pid].at(_from + index);
		}
		return results;
	}

	function getSubPoolUserStakes(
		uint256 _pid,
		uint256 _from,
		uint256 _length
	) external view returns (address[] memory, uint256[] memory) {
		uint256 _poolUserLength = poolUsers[_pid].length();
		if (_from.add(_length) > _poolUserLength) {
			_length = _poolUserLength.sub(_from);
		}
		address[] memory results = new address[](_length);
		uint256[] memory stakeAmount = new uint256[](_length);
		for (uint256 index = 0; index < _length; index++) {
			results[index] = poolUsers[_pid].at(_from + index);
			stakeAmount[index] = userInfo[_pid][results[index]].amount;
		}
		return (results, stakeAmount);
	}


	function setTokenPerSecond(uint256 _tokenPerSecond, bool _withUpdate) external onlyOwner {
		if (_withUpdate) {
			massUpdatePools();
		}
		tokenPerSecond = _tokenPerSecond;
	}

	function setFee(uint256 _stakeFee, uint256 _withdrawFee) external onlyOwner {
		require(_stakeFee <= 500, "_stakeFee failed");
		require(_withdrawFee <= 2000, "_withdrawFee failed");
		stakeFee = _stakeFee;
		withdrawFee = _withdrawFee;
	}


	function setRewardAddress(address _rewardAddress) external onlyOwner {
		require(_rewardAddress <= address(0), "_rewardAddress failed");
		rewardAddress = _rewardAddress;
	}

	function add(
		uint256 _allocPoint,
		IERC20 _poolToken,
		uint256 _lockDuration,
		bool _withUpdate
	) external onlyOwner {
		if (_withUpdate) {
			massUpdatePools();
		}
		uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
		totalAllocPoint = totalAllocPoint.add(_allocPoint);
		poolInfo.push(
			PoolInfo({
				poolToken: _poolToken,
				allocPoint: _allocPoint,
				lastRewardTime: lastRewardTime,
				accRewardPerShare: 0,
				amount: 0,
				lockDuration: _lockDuration
			})
		);
	}

	function set(
		uint256 _pid,
		uint256 _allocPoint,
		bool _withUpdate
	) external onlyOwner verifyPoolId(_pid) {
		if (poolInfo[_pid].allocPoint != _allocPoint) {
			if (_withUpdate) {
				massUpdatePools();
			}
			totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
			poolInfo[_pid].allocPoint = _allocPoint;
		}
	}

	function setLockDuration(uint256 _pid, uint256 _lockDuration) external onlyOwner verifyPoolId(_pid) {
		if (poolInfo[_pid].lockDuration != _lockDuration) {
			poolInfo[_pid].lockDuration = _lockDuration;
		}
	}

	
}