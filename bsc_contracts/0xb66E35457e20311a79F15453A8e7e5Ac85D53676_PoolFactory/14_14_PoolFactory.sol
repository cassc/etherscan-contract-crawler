/*
PoolFactory

https://github.com/FanbaseEU/Staking_Ethereum_SmartContracts

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "./interfaces/IPoolFactory.sol";
import "./interfaces/IModuleFactory.sol";
import "./interfaces/IStakingModule.sol";
import "./interfaces/IRewardModule.sol";
import "./OwnerController.sol";
import "./Pool.sol";

/**
 * @title Pool factory
 *
 * @notice this implements the Pool factory contract which allows any user to
 * easily configure and deploy their own Pool
 *
 * @dev it relies on a system of sub-factories which are responsible for the
 * creation of underlying staking and reward modules. This primary factory
 * calls each module factory and assembles the overall Pool contract.
 *
 * this contract also manages various privileged platform settings including
 * treasury address, fee amount, and module factory whitelist.
 */
contract PoolFactory is IPoolFactory, OwnerController {
	// events
	event PoolCreated(address indexed user, address pool);
	event FeeUpdated(uint256 previous, uint256 updated);
	event TreasuryUpdated(address previous, address updated);
	event WhitelistUpdated(
		address indexed factory,
		uint256 previous,
		uint256 updated
	);

	// types
	enum ModuleFactoryType {
		Unknown,
		Staking,
		Reward
	}

	// constants
	uint256 public constant MAX_FEE = 20 * 10 ** 16; // 20%

	// fields
	mapping(address => bool) public map;
	address[] public list;
	address private _gysr;
	address private _treasury;
	uint256 private _fee;
	mapping(address => ModuleFactoryType) public whitelist;

	// time lock
	uint256 private constant _TIMELOCK = 2 days;
	uint256 public timelock;

	//time lock
	modifier notLocked() {
		require(
			timelock != 0 && timelock <= block.timestamp,
			"Function is timelocked"
		);
		_;
	}

	/**
	 * @param gysr_ address of GYSR token
	 */
	constructor(address gysr_, address treasury_) {
		_gysr = gysr_;
		_treasury = treasury_;
		_fee = MAX_FEE;
	}

	/**
	 * @notice create a new Pool
	 * @param staking address of factory that will be used to create staking module
	 * @param reward address of factory that will be used to create reward module
	 * @param stakingdata construction data for staking module factory
	 * @param rewarddata construction data for reward module factory
	 * @return address of newly created Pool
	 */
	function create(
		address staking,
		address reward,
		bytes calldata stakingdata,
		bytes calldata rewarddata
	) external returns (address) {
		// validate
		require(
			whitelist[staking] == ModuleFactoryType.Staking,
			"Not found in whitelist of staking module"
		);
		require(
			whitelist[reward] == ModuleFactoryType.Reward,
			"Not found in whitelist of reward module"
		);

		// create modules
		address stakingModule = IModuleFactory(staking).createModule(
			stakingdata
		);
		address rewardModule = IModuleFactory(reward).createModule(rewarddata);

		// create pool
		Pool pool = new Pool(
			stakingModule,
			rewardModule,
			_gysr,
			address(this)
		);

		// set access
		IStakingModule(stakingModule).transferOwnership(address(pool));
		IRewardModule(rewardModule).transferOwnership(address(pool));
		pool.transferControl(msg.sender); // this also sets controller for modules
		pool.transferOwnership(msg.sender);

		// bookkeeping
		map[address(pool)] = true;
		list.push(address(pool));

		// output
		emit PoolCreated(msg.sender, address(pool));
		return address(pool);
	}

	//unlock timelock
	function unlockFunction() public onlyOwner {
		timelock = block.timestamp + _TIMELOCK;
	}

	//lock timelock
	function lockFunction() public onlyOwner {
		timelock = 0;
	}

	/**
	 * @inheritdoc IPoolFactory
	 */
	function treasury() external view override returns (address) {
		return _treasury;
	}

	/**
	 * @inheritdoc IPoolFactory
	 */
	function fee() external view override returns (uint256) {
		return _fee;
	}

	/**
	 * @notice update the GYSR treasury address
	 * @param treasury_ new value for treasury address
	 */
	function setTreasury(address treasury_) external notLocked {
		requireController();
		emit TreasuryUpdated(_treasury, treasury_);
		_treasury = treasury_;
	}

	/**
	 * @notice update the global GYSR spending fee
	 * @param fee_ new value for GYSR spending fee
	 */
	function setFee(uint256 fee_) external notLocked {
		requireController();
		require(fee_ <= MAX_FEE, "Fee can't be set as exceed Max value");
		emit FeeUpdated(_fee, fee_);
		_fee = fee_;
	}

	/**
	 * @notice set the whitelist status of a module factory
	 * @param factory_ address of module factory
	 * @param type_ updated whitelist status for module
	 */
	function setWhitelist(address factory_, uint256 type_) external {
		requireController();
		require(
			type_ <= uint256(ModuleFactoryType.Reward),
			"Module Type Error!"
		);
		require(factory_ != address(0), "Factory address can't be zero");
		emit WhitelistUpdated(factory_, uint256(whitelist[factory_]), type_);
		whitelist[factory_] = ModuleFactoryType(type_);
	}

	/**
	 * @return total number of Pools created by the factory
	 */
	function count() public view returns (uint256) {
		return list.length;
	}
}