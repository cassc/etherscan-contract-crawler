// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import { ERC20Upgradeable as ERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ISuperComposableYield } from "../../interfaces/ERC5115/ISuperComposableYield.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20MetadataUpgradeable as IERC20Metadata } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import { Accounting } from "../../common/Accounting.sol";
// import { ERC20PermitUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import { SectorErrors } from "../../interfaces/SectorErrors.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { FeesU } from "../../common/FeesU.sol";

// import "hardhat/console.sol";

abstract contract SCYBaseU is
	Initializable,
	ISuperComposableYield,
	ReentrancyGuardUpgradeable,
	ERC20,
	Accounting,
	FeesU,
	SectorErrors
	// ERC20PermitUpgradeable,
{
	using SafeERC20 for IERC20;

	address internal constant NATIVE = address(0);
	uint256 internal constant ONE = 1e18;
	uint256 public constant MIN_LIQUIDITY = 1e3;

	uint256 public version;

	// solhint-disable no-empty-blocks
	receive() external payable {}

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		_disableInitializers();
	}

	function __SCYBase_init(string memory _name, string memory _symbol) internal onlyInitializing {
		__ReentrancyGuard_init();
		__ERC20_init(_name, _symbol);
		// __ERC20Permit_init(_name);
	}

	/*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

	/**
	 * @dev See {ISuperComposableYield-deposit}
	 */
	function deposit(
		address receiver,
		address tokenIn,
		uint256 amountTokenToPull,
		uint256 minSharesOut
	) external payable nonReentrant returns (uint256 amountSharesOut) {
		require(isValidBaseToken(tokenIn), "SCY: Invalid tokenIn");

		if (tokenIn == NATIVE && amountTokenToPull != 0) revert CantPullEth();
		else if (amountTokenToPull != 0) _transferIn(tokenIn, msg.sender, amountTokenToPull);

		// this depends on strategy
		// this supports depositing directly into strategy to save gas
		uint256 amountIn = getFloatingAmount(tokenIn);
		if (amountIn == 0) revert ZeroAmount();

		amountSharesOut = _deposit(receiver, tokenIn, amountIn);
		if (amountSharesOut < minSharesOut) revert InsufficientOut(amountSharesOut, minSharesOut);

		// lock minimum liquidity if totalSupply is 0
		if (totalSupply() == 0) {
			if (MIN_LIQUIDITY > amountSharesOut) revert MinLiquidity();
			amountSharesOut -= MIN_LIQUIDITY;
			_mint(address(1), MIN_LIQUIDITY);
		}

		_mint(receiver, amountSharesOut);
		emit Deposit(msg.sender, receiver, tokenIn, amountIn, amountSharesOut);
	}

	/**
	 * @dev See {ISuperComposableYield-redeem}
	 */
	function redeem(
		address receiver,
		uint256 amountSharesToRedeem,
		address tokenOut,
		uint256 minTokenOut
	) external nonReentrant returns (uint256 amountTokenOut) {
		require(isValidBaseToken(tokenOut), "SCY: invalid tokenOut");

		// this is to handle a case where the strategy sends funds directly to user
		uint256 amountToTransfer;
		(amountTokenOut, amountToTransfer) = _redeem(receiver, tokenOut, amountSharesToRedeem);
		if (amountTokenOut < minTokenOut) revert InsufficientOut(amountTokenOut, minTokenOut);

		if (amountToTransfer > 0) _transferOut(tokenOut, receiver, amountToTransfer);

		emit Redeem(msg.sender, receiver, tokenOut, amountSharesToRedeem, amountTokenOut);
	}

	/**
	 * @notice mint shares based on the deposited base tokens
	 * @param tokenIn base token address used to mint shares
	 * @param amountDeposited amount of base tokens deposited
	 * @return amountSharesOut amount of shares minted
	 */
	function _deposit(
		address receiver,
		address tokenIn,
		uint256 amountDeposited
	) internal virtual returns (uint256 amountSharesOut);

	/**
	 * @notice redeems base tokens based on amount of shares to be burned
	 * @param tokenOut address of the base token to be redeemed
	 * @param amountSharesToRedeem amount of shares to be burned
	 * @return amountTokenOut amount of base tokens redeemed
	 */
	function _redeem(
		address receiver,
		address tokenOut,
		uint256 amountSharesToRedeem
	) internal virtual returns (uint256 amountTokenOut, uint256 tokensToTransfer);

	// VIRTUALS
	function getFloatingAmount(address token) public view virtual returns (uint256);

	/**
	 * @notice See {ISuperComposableYield-getBaseTokens}
	 */
	function getBaseTokens() external view virtual override returns (address[] memory res);

	/**
	 * @dev See {ISuperComposableYield-isValidBaseToken}
	 */
	function isValidBaseToken(address token) public view virtual override returns (bool);

	function _transferIn(
		address token,
		address to,
		uint256 amount
	) internal virtual;

	function _transferOut(
		address token,
		address to,
		uint256 amount
	) internal virtual;

	function _depositNative() internal virtual;

	// OVERRIDES
	function totalSupply() public view virtual override(Accounting, ERC20) returns (uint256) {
		return ERC20.totalSupply();
	}

	function sendERC20ToStrategy() public view virtual returns (bool) {
		return true;
	}

	error CantPullEth();
	error InsufficientOut(uint256 amountOut, uint256 minOut);

	uint256[50] private __gap;
}