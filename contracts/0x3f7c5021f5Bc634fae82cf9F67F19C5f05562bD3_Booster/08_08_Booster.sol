// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ILocker.sol";
import "../interfaces/IProxyVault.sol";
import "../interfaces/IFraxStrategy.sol";
import "../interfaces/IPoolRegistry.sol";

contract Booster {
	using SafeERC20 for IERC20;

	address public constant FXS = address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);

	address public strategy;

	address public immutable proxy;
	address public immutable poolRegistry;

	address public owner;
	address public pendingOwner;
	address public poolManager;

	constructor(address _proxy, address _poolReg, address _strategy) {
		proxy = _proxy;
		strategy = _strategy;
		poolRegistry = _poolReg;
		owner = msg.sender;
		poolManager = msg.sender;
	}

	modifier onlyOwner() {
		require(owner == msg.sender, "!auth");
		_;
	}

	modifier onlyPoolManager() {
		require(poolManager == msg.sender, "!auth");
		_;
	}

	// ########################### Public function ######################### //
	// #=#=#=#=#=#=#=#=#=#=# Personal Vault Section  #=#=#=#=#=#=#=#=#=#=#=# //

	/// @notice create a vault for a user
	/// @param _pid pool id 
	function createVault(uint256 _pid) external {
		//create minimal proxy vault for specified pool
		(address vault, address stakeAddress, address stakeToken, address rewards) = IPoolRegistry(poolRegistry)
			.addUserVault(_pid, msg.sender);
		//make voterProxy call proxyToggleStaker(vault) on the pool's stakingAddress to set it as a proxied child
		bytes memory data = abi.encodeWithSelector(bytes4(keccak256("proxyToggleStaker(address)")), vault);
		IFraxStrategy(strategy).proxyCall(stakeAddress, data);

		//call proxy initialize
		IProxyVault(vault).initialize(msg.sender, stakeAddress, stakeToken, rewards);

		//set vault veFXS proxy
		data = abi.encodeWithSelector(bytes4(keccak256("setVeFXSProxy(address)")), proxy);
		IFraxStrategy(strategy).proxyCall(vault, data);
	}

	// #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=# //

	// ######################## Restricted function ######################## //
	// #=#=#=#=#=#=#=#=#=#  Booster Management Section #=#=#=#=#=#=#=#=#=#=# //

	/// @notice set pending owner
	/// @param _po pending owner address
	function setPendingOwner(address _po) external onlyOwner {
		pendingOwner = _po;
		emit SetPendingOwner(_po);
	}

	/// @notice claim ownership
	function acceptPendingOwner() external {
		require(pendingOwner != address(0) && msg.sender == pendingOwner, "!p_owner");

		owner = pendingOwner;
		pendingOwner = address(0);
		emit OwnerChanged(owner);
	}

	/// @notice set pool manager
	/// @param _pmanager new pool manager address
	function setPoolManager(address _pmanager) external onlyOwner {
		poolManager = _pmanager;
		emit PoolManagerChanged(_pmanager);
	}

	/// @notice recover tokens on this contract
	/// @param _tokenAddress token address to rescue
	/// @param _tokenAmount amount of token to rescue
	/// @param _withdrawTo address to transfer rescued token
	function recoverERC20(
		address _tokenAddress,
		uint256 _tokenAmount,
		address _withdrawTo
	) external onlyOwner {
		IERC20(_tokenAddress).safeTransfer(_withdrawTo, _tokenAmount);
		emit Recovered(_tokenAddress, _tokenAmount);
	}

	// #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=# //

	// #=#=#=#=#=#=#=# Start Pool Registry Management Section #=#=#=#=#=#=#=# //

	/* ---- Setter ---- */
	/// @notice set new operator on pool registry
	/// @param _op new operator address
	function setOperator(address _op) external onlyPoolManager {
		IPoolRegistry(poolRegistry).setOperator(_op);
	}

	/// @notice set new distributor on pool registry
	/// @param _distributor new distributor address
	function setDistributor(address _distributor) external onlyPoolManager {
		IPoolRegistry(poolRegistry).setDistributor(_distributor);
	}

	/// @notice set a new reward pool implementation for future pools on pool registry 
	/// @param _impl new reward pool address
	function setPoolRewardImplementation(address _impl) external onlyPoolManager {
		IPoolRegistry(poolRegistry).setRewardImplementation(_impl);
	}

	/* ---- Pool management ---- */
	/// @notice add a new pool and implementation on pool registry
	/// @param _implementation personal vault contract model address
	/// @param _stakingAddress Frax gauge stacking LP token address
	/// @param _stakingToken LP token address for Frax gauge
	function addPool(
		address _implementation,
		address _stakingAddress,
		address _stakingToken
	) external onlyPoolManager {
		IPoolRegistry(poolRegistry).addPool(_implementation, _stakingAddress, _stakingToken);
	}

	/// @notice update rewards contract on a specific pool, when updated with setRewardImplementation().
	/// @dev each user must call changeRewards on vault to update to new contract
	/// @param _pid pool id for the new rewards contract
	function createNewPoolRewards(uint256 _pid) external onlyPoolManager {
		IPoolRegistry(poolRegistry).createNewPoolRewards(_pid);
	}

	/// @notice deactivates pool so that new vaults can not be made on pool registry.
	/// @dev can not force shutdown/withdraw user funds
	/// @param _pid pool id to desactivate
	function deactivatePool(uint256 _pid) external onlyPoolManager {
		IPoolRegistry(poolRegistry).deactivatePool(_pid);
	}

	/// @notice Set strategy to interact with Locker.
	/// @param _strategy new strategy
	function setStrategy(address _strategy) external onlyPoolManager {
		strategy = _strategy;
	}

	// #=#=#=#=#=#=#=#=#=#=#=#=#=#=#    EVENTS   #=#=#=#=#=#=#=#=#=#=#=#=#=# //
	event SetPendingOwner(address indexed _address);
	event OwnerChanged(address indexed _address);
	event PoolManagerChanged(address indexed _address);
	event Recovered(address indexed _token, uint256 _amount);
}