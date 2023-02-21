// SPDX-License-identifier: MIT
pragma solidity 0.6.11;

import "../interfaces/IPCAPool.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import { ERC20PausableUpgradeable as PauseableERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20PausableUpgradeable.sol";
import { ERC20Upgradeable as ERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { OwnableUpgradeable as Ownable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import { ReentrancyGuardUpgradeable as NonReentrant } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract PCAPool is IPCAPool, Initializable, Ownable, PauseableERC20, NonReentrant {
	using SafeERC20 for ERC20;

	ILiquidityPool public pool;
	ERC20 public underlyer;

	//@custom:oz-upgrades-unsafe-allow constructor
	//solhint-disable-next-line no-empty-blocks
	constructor() public initializer {}

	function initialize(ILiquidityPool _pool, string memory _name, string memory _symbol) external initializer {
		require(address(_pool) != address(0), "ZERO_ADDRESS");

		__Context_init_unchained();
		__Ownable_init_unchained();
		__Pausable_init_unchained();
		__ReentrancyGuard_init_unchained();
		__ERC20_init_unchained(_name, _symbol);
		__ERC20Pausable_init_unchained();

		pool = _pool;
		underlyer = pool.underlyer();
		require(address(underlyer) != address(0), "POOL_DNE");
	}

	function decimals() public view override returns (uint8) {
		return underlyer.decimals();
	}

	function depositAsset(address account, uint256 amount) external override whenNotPaused {
		require(account != address(0), "INVALID_ADDRESS");
		require(amount > 0, "INVALID_AMOUNT");
		_mint(account, amount);
		underlyer.safeTransferFrom(msg.sender, address(pool), amount);
	}

	function depositPoolAsset(address account, uint256 amount) external override whenNotPaused nonReentrant {
		require(account != address(0), "INVALID_ADDRESS");
		require(amount > 0, "INVALID_AMOUNT");
		_mint(account, amount);
		pool.controlledBurn(amount, msg.sender);
	}

	function updatePool(ILiquidityPool newPool) external override onlyOwner {
		address poolAddress = address(newPool);
		require(poolAddress != address(0), "INVALID_ADDRESS");
		require(address(newPool.underlyer()) == address(underlyer), "UNDERLYER_MISMATCH");
		pool = newPool;

		emit PoolUpdated(poolAddress);
	}

	function pause() external override onlyOwner {
		_pause();
	}

	function unpause() external override onlyOwner {
		_unpause();
	}
}