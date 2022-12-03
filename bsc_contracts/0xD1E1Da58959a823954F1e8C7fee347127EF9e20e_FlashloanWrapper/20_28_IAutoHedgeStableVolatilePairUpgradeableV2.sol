pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IComptroller.sol";
import "./ICErc20.sol";
import "./IWETHUnwrapper.sol";
import "./IFlashloanWrapper.sol";
import "./IAutoHedgeStableVolatileFactoryUpgradeableV2.sol";
import "./autonomy/IRegistry.sol";

interface IAutoHedgeStableVolatilePairUpgradeableV2 {
	struct Amounts {
		uint256 stable;
		uint256 vol;
	}

	struct MmBps {
		uint64 min;
		uint64 max;
	}

	struct VolPosition {
		uint256 owned;
		uint256 debt;
		uint256 bps;
	}

	struct Tokens {
		IERC20Metadata stable;
		IERC20Metadata vol;
		ICErc20 cVol;
		IERC20Metadata uniLp;
		ICErc20 cUniLp;
	}

	struct FinishDeposit {
		IFlashloanWrapper.FinishRoute fr;
		address depositor;
		uint256 amountStableInit;
		uint256 amountVolToFlashloan;
		address to;
		address referrer;
		uint256 flashloanFee;
	}

	struct FinishWithdraw {
		IFlashloanWrapper.FinishRoute fr;
		address withrawer;
		uint256 liquidity;
		uint256 amountVolToFlashloan;
		address to;
		uint256 flashloanFee;
	}

	struct TokenUnderlyingBalances {
		uint256 amountVolBorrow;
		uint256 balanceOfUniLp;
	}

	event Deposited(
		address indexed user,
		uint256 amountStable,
		uint256 amountVol,
		uint256 amountUniLp,
		uint256 amountStableSwap,
		uint256 amountMinted
	);

	event Withdrawn(
		address indexed user,
		uint256 amountStableToUser,
		uint256 amountVolToRepay,
		uint256 amountBurned
	);

	event TokenUnderlyingBalancesUpdated(uint256 cVolBorrowAmount, uint256 cUniLpBalance);

	function initialize(
		IUniswapV2Router02 uniV2Router_,
		Tokens memory tokens,
		IERC20Metadata weth_,
		string memory name_,
		string memory symbol_,
		IRegistry registry_,
		address userFeeVeriForwarder_,
		MmBps memory mmBps_,
		IComptroller _comptroller,
		IAutoHedgeStableVolatileFactoryUpgradeableV2 factory_,
		IWETHUnwrapper wu_
	) external;

	/**
	 * @notice  Deposit stablecoins into this pair and receive back AH LP
	 *          tokens. This fcn:
	 *              1. Swaps half the stables into whatever the volatile
	 *                  token is
	 *              2. LPs both tokens on a DEX
	 *              3. Lends out the DEX LP token on Fuse/Midas (Compound
	 *                  fork platforms) to use as collateral
	 *              4. Borrows an equal amount of vol token that was LP'd with
	 *              5. Swaps it to the stable token
	 *              6. Lends out the stable token
	 *              7. Mints an AH LP token and sends it to the user.
	 *          Note depositing takes a 0.3% fee, either to Autonomy or a
	 *          referrer if there is 1.
	 * @param amountStableInit   The minimum amount of the stable that's
	 *                              accepted to be put into the LP
	 * @param to    The address to send the AH LP tokens to
	 * @param referrer  The addresses that receives the 0.3% protocol fee on
	 *                  deposits. If left as 0x00...00, it goes to Autonomy
	 */
	function deposit(
		uint256 amountStableInit,
		address to,
		address referrer
	) external;

	// /**
	//  * @notice  Withdraws stablecoins from the position by effectively
	//  *          doing everything in `deposit` in reverse order. There is
	//  *          no protocol or referrer fee for withdrawing. All positions
	//  *          are withdrawn proportionally - for example if `liquidity`
	//  *          is 10% of the pair's AH LP supply, then it'll withdraw
	//  *          10% of the stable lending position, 10% of the DEX LP,
	//  *          and be responsible for repaying 10% of the vol debt.
	//  * @param liquidity     The amount of AH LP tokens to burn
	//  * @return amountStableToUser   The amount of stables that are actually sent to the user
	//  *          after all positions have been withdrawn/repaid
	//  */
	// function withdraw(uint256 liquidity, UniArgs calldata uniArgs)
	//     external
	//     returns (uint256 amountStableToUser);

	/**
	 * @notice  This is only callable by Autonomy Network itself and only
	 *          under the condition of the vol debt being more than a set
	 *          difference (1% by default) with the amount of vol owned in
	 *          the DEX LP.
	 *          If there is more debt than in the DEX LP, it
	 *          takes some stables from the lending position, withdraws them,
	 *          swaps them to vol, and repays the debt.
	 *          If there is less debt than in the DEX LP, then more vol is
	 *          borrowed, swapped into stables, and lent out.
	 * @param user  The user who made this automation request. This must
	 *              be address(this) of the pair contract, else it'll revert
	 * @param feeAmount     The amount of fee (in the native token of the chain)
	 *                      that's needed to pay the automation fee
	 */
	function rebalanceAuto(address user, uint256 feeAmount) external;

	function finishDeposit(bytes calldata data) external;

	function finishWithdraw(bytes calldata data) external returns (uint256);

	/**
	 * @notice  Returns information on the positions of the volatile token
	 * @return  The VolPosition struct which specifies what amount of vol
	 *          tokens are owned in the DEX LP, the amount of vol tokens
	 *          in debt, and bps, which is basically debt/owned, scaled
	 *          by 1e18
	 */
	function getDebtBps() external returns (VolPosition memory);

	/**
	 * @notice  Returns the factory that created this pair
	 */
	function factory() external returns (IAutoHedgeStableVolatileFactoryUpgradeableV2);

	/**
	 * @notice  Set the min and max bps that the pool will use to rebalance,
	 *          scaled to 1e18. E.g. the min by default is a 1% difference
	 *          and is therefore 99e16
	 * @param newMmBps  The MmBps struct that specifies the min then the max
	 */
	function setMmBps(MmBps calldata newMmBps) external;

	/**
	 * @notice  Gets the token addresses involved in the pool and their
	 *          corresponding cToken/fToken addresses
	 */
	function getTokens()
		external
		view
		returns (
			IERC20Metadata stable,
			IERC20Metadata vol,
			ICErc20 cVol,
			IERC20Metadata uniLp,
			ICErc20 cUniLp
		);

	function balanceOfVolBorrow() external view returns (uint256);

	function balanceOfUniLp() external view returns (uint256);

	// function getBalanceOfUnderlyingTokens()
	// 	external
	// 	view
	// 	returns (uint256 amountVolBorrow, uint256 balanceOfUniLp);

	// function refreshBalanceOfUnderlyingTokens() external;
}