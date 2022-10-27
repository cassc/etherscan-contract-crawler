// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/token/ERC20/IERC20.sol";
import "./IFermion.sol";
import "./IMigratorDevice.sol";
import "./IMagneticFieldGeneratorStore.sol";

interface IMagneticFieldGenerator
{
	event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
	event Harvest(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
	event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
	event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken);
	event LogSetPool(uint256 indexed pid, uint256 allocPoint);
	event LogUpdatePool(uint256 indexed pid, uint256 lastRewardBlock, uint256 lpSupply, uint256 accFermionPerShare);
	event Migrate(uint256 indexed pid, uint256 balance, IERC20 indexed fromToken, IERC20 indexed toToken);
	event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);

	/// @notice Add a new LP to the pool. Can only be called by the owner.
	/// WARNING DO NOT add the same LP token more than once. Rewards will be messed up if you do.
	/// @param allocPoint AP of the new pool.
	/// @param lpToken Address of the LP ERC-20 token.
	/// @param lockPeriod Number of Blocks the pool should disallow withdraws of all kind.
	function add(uint256 allocPoint, IERC20 lpToken, uint256 lockPeriod) external;
	function deposit(uint256 pid, uint256 amount, address to) external;
	function disablePool(uint256 pid) external;
	function emergencyWithdraw(uint256 pid, address to) external;
	function handOverToSuccessor(IMagneticFieldGenerator successor) external;
	function harvest(uint256 pid, address to) external;
	function massUpdatePools() external;
	function migrate(uint256 pid) external;
	function renounceOwnership() external;
	function set(uint256 pid, uint256 allocPoint) external;
	function setFermionPerBlock(uint256 fermionPerBlock) external;
	function setMigrator(IMigratorDevice migratorContract) external;
	function setStore(IMagneticFieldGeneratorStore storeContract) external;
	function transferOwnership(address newOwner) external;
	function updatePool(uint256 pid) external returns(PoolInfo memory);
	function withdraw(uint256 pid, uint256 amount, address to) external;
	function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;

	function getFermionContract() external view returns (IFermion);
	function getFermionPerBlock() external view returns (uint256);
	function getStartBlock() external view returns (uint256);
	function migrator() external view returns(IMigratorDevice);
	function owner() external view returns (address);
	function pendingFermion(uint256 pid, address user) external view returns (uint256);
	function poolInfo(uint256 pid) external view returns (PoolInfo memory);
	function poolLength() external view returns (uint256);
	function successor() external view returns (IMagneticFieldGenerator);
	function totalAllocPoint() external view returns (uint256);
	function userInfo(uint256 pid, address user) external view returns (UserInfo memory);
}