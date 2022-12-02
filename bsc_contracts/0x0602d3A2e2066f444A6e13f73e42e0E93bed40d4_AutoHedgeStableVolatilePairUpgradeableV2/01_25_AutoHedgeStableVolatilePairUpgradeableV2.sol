pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IComptroller.sol";
import "../interfaces/ICErc20.sol";
import "../interfaces/IAutoHedgeStableVolatilePairUpgradeableV2.sol";
import "../interfaces/IAutoHedgeStableVolatileFactoryUpgradeableV2.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/autonomy/IRegistry.sol";
import "./UniswapV2ERC20Upgradeable.sol";
import "./Maths.sol";

/**
 * @title    AutoHedgeStableVolatilePair
 * @notice   AutoHedge allows users to LP on DEXes while remaining
 *           delta-neutral, i.e. if they deposit $100 onto an AH
 *           pair that has an underlying DEX pair of DAI-ETH, then
 *           even when the price of ETH doubles or halves, the position
 *           value is still worth exactly $100, and accumulates LP
 *           trading fees ontop. This is the 1st iteration of AH and
 *           only works with a DEX pair where 1 of the assets is a
 *           stablecoin.
 * @author   Quantaf1re (James Key)
 */
contract AutoHedgeStableVolatilePairUpgradeableV2 is
	IAutoHedgeStableVolatilePairUpgradeableV2,
	Initializable,
	OwnableUpgradeable,
	ReentrancyGuardUpgradeable,
	UniswapV2ERC20Upgradeable
{
	using SafeERC20 for IERC20Metadata;

	function initialize(
		IUniswapV2Router02 uniV2Router_,
		Tokens memory tokens_,
		IERC20Metadata weth_,
		string memory name_,
		string memory symbol_,
		IRegistry registry_,
		address userFeeVeriForwarder_,
		MmBps memory mmBps_,
		IComptroller _comptroller,
		IAutoHedgeStableVolatileFactoryUpgradeableV2 factory_,
		IWETHUnwrapper wu_
	) public override initializer {
		__Ownable_init_unchained();
		__UniswapV2ERC20Upgradeable__init_unchained(name_, symbol_);

		uniV2Router = uniV2Router_;
		tokens = tokens_;
		weth = weth_;
		registry = registry_;
		userFeeVeriForwarder = userFeeVeriForwarder_;
		mmBps = mmBps_;
		factory = factory_;
		wu = wu_;

		tokens_.stable.safeApprove(address(uniV2Router), MAX_UINT);
		tokens_.vol.safeApprove(address(uniV2Router), MAX_UINT);
		tokens_.vol.safeApprove(address(tokens_.cVol), MAX_UINT);
		tokens_.uniLp.safeApprove(address(uniV2Router), MAX_UINT);
		tokens_.uniLp.safeApprove(address(tokens_.cUniLp), MAX_UINT);

		address[] memory cTokens = new address[](2);
		cTokens[0] = address(tokens_.cVol);
		cTokens[1] = address(tokens_.cUniLp);
		uint256[] memory results = _comptroller.enterMarkets(cTokens);
		require(results[0] == 0 && results[1] == 0, "AHV2: unable to enter markets");

		autoId = registry_.newReqPaySpecific(
			address(this),
			payable(address(0)),
			abi.encodeWithSelector(this.rebalanceAuto.selector, address(this), 0),
			0,
			true,
			true,
			false,
			true
		);
	}

	uint256 private constant MINIMUM_LIQUIDITY = 10**3;
	uint256 private constant BASE_FACTOR = 1e18;
	uint256 private constant MAX_UINT = type(uint256).max;

	IRegistry public registry;
	address public userFeeVeriForwarder;
	uint256 public autoId;

	IUniswapV2Router02 public uniV2Router;

	Tokens public tokens;
	IERC20Metadata public weth;

	MmBps public mmBps;

	IAutoHedgeStableVolatileFactoryUpgradeableV2 public override factory;

	// TokenUnderlyingBalances private balanceOfUnderlyingTokens;

	uint256 public override balanceOfVolBorrow;
	uint256 public override balanceOfUniLp;

	uint256 private constant FLASH_LOAN_FEE = 50;
	uint256 private constant FLASH_LOAN_FEE_PRECISION = 1e5;

	IWETHUnwrapper public wu;

	modifier _updateBalanceOfUnderlyingTokens() {
		_;
		Tokens memory _tokens = tokens;

		// uint256 amountVolBorrow = _tokens.cVol.borrowBalanceCurrent(address(this));
		// uint256 uniLpBalance = _tokens.cUniLp.balanceOfUnderlying(address(this));

		balanceOfVolBorrow = _tokens.cVol.borrowBalanceCurrent(address(this));
		balanceOfUniLp = _tokens.cUniLp.balanceOfUnderlying(address(this));

		// balanceOfUnderlyingTokens = TokenUnderlyingBalances(amountVolBorrow, uniLpBalance);

		emit TokenUnderlyingBalancesUpdated(balanceOfVolBorrow, balanceOfUniLp);
	}

	modifier onlyFlw() {
		require(msg.sender == factory.flw(), "AHV2: invalid caller");
		_;
	}

	function deposit(
		uint256 amountStableInit,
		address to,
		address referrer
	) external override nonReentrant {
		Tokens memory _tokens = tokens;

		uint256 reserveVol = _tokens.vol.balanceOf(address(_tokens.uniLp));
		uint256 reserveStable = _tokens.stable.balanceOf(address(_tokens.uniLp));

		uint256 t = ((reserveStable * FLASH_LOAN_FEE * 997)) / FLASH_LOAN_FEE_PRECISION;

		uint256 w = (amountStableInit * reserveVol * FLASH_LOAN_FEE * 997) /
			FLASH_LOAN_FEE_PRECISION +
			reserveStable *
			reserveVol *
			997 +
			(reserveVol * reserveStable * 1000 * FLASH_LOAN_FEE) /
			FLASH_LOAN_FEE_PRECISION;

		uint256 z = amountStableInit * reserveVol * reserveVol * 997;
		uint256 amountVolToFlashloan = (w - (Maths.sqrt((w - (4 * t) * (z / w))) * Maths.sqrt(w))) /
			(2 * t);

		// flwCaller and target both should be pair address as we are calling from pair contract direclty
		IFlashloanWrapper.FinishRoute memory fr = IFlashloanWrapper.FinishRoute(
			address(this),
			address(this)
		);
		FinishDeposit memory fd = FinishDeposit(
			fr,
			msg.sender,
			amountStableInit,
			amountVolToFlashloan,
			to,
			referrer
		);
		bytes memory data = abi.encodeWithSelector(
			IAutoHedgeStableVolatilePairUpgradeableV2.finishDeposit.selector,
			abi.encode(fd)
		);
		IFlashloanWrapper flw = IFlashloanWrapper(factory.flw());
		flw.takeOutFlashLoan(IERC20(address(_tokens.vol)), amountVolToFlashloan, data);
	}

	function withdraw(uint256 liquidity, address to) external nonReentrant {
		Tokens memory _tokens = tokens;
		uint256 amountVolToFlashloan = (_tokens.cVol.borrowBalanceCurrent(address(this)) *
			liquidity) / totalSupply;

		// flwCaller and target both should be pair address as we are calling from pair contract direclty
		IFlashloanWrapper.FinishRoute memory fr = IFlashloanWrapper.FinishRoute(
			address(this),
			address(this)
		);
		FinishWithdraw memory fw = FinishWithdraw(
			fr,
			msg.sender,
			liquidity,
			amountVolToFlashloan,
			to
		);
		bytes memory data = abi.encodeWithSelector(
			IAutoHedgeStableVolatilePairUpgradeableV2.finishWithdraw.selector,
			abi.encode(fw)
		);
		IFlashloanWrapper flw = IFlashloanWrapper(factory.flw());
		flw.takeOutFlashLoan(IERC20(address(_tokens.vol)), amountVolToFlashloan, data);
	}

	function finishDeposit(bytes calldata data)
		external
		override
		onlyFlw
		_updateBalanceOfUnderlyingTokens
	{
		FinishDeposit memory fd = abi.decode(data, (FinishDeposit));
		uint256 fee = (fd.amountVolToFlashloan * FLASH_LOAN_FEE) / FLASH_LOAN_FEE_PRECISION;
		uint256 repayAmount = fd.amountVolToFlashloan + fee;
		// Get stables from the user
		tokens.stable.safeTransferFrom(fd.depositor, address(this), fd.amountStableInit);

		address[] memory pathStableToVol = newPath(tokens.stable, tokens.vol);

		// Get the extra amount of vol needed for the flashloan fee. We need to keep any excess
		// vol from the LP because `amountVol` (which will be borrowed back from Fuse exactly) + the
		// excess = `amountStableLiq` which is the amount we need to repay, then the fee on top.
		// There should never be a situation where this contract is left with a non-zero amount of vol
		// Using the max input at `amountStableInit` is not front-runnable because if all of it is used,
		// then there won't be enough for `amountStableLiqMin` when LPing
		uint256[] memory amountsStableToVol = uniV2Router.swapTokensForExactTokens(
			fee,
			fd.amountStableInit,
			pathStableToVol,
			address(this),
			MAX_UINT
		);
		(uint256 amountStable, uint256 amountVol, uint256 amountUniLp) = uniV2Router.addLiquidity(
			address(tokens.stable),
			address(tokens.vol),
			fd.amountStableInit - amountsStableToVol[0],
			fd.amountVolToFlashloan,
			0,
			0,
			address(this),
			MAX_UINT
		);

		// Transfer not used tokens back to the user
		uint256 amountStableRemaining = fd.amountStableInit - amountsStableToVol[0];
		if (amountStableRemaining > amountStable) {
			tokens.stable.safeTransfer(fd.depositor, amountStableRemaining - amountStable);
		}
		// Need to know the % increase of the DEX position so that we give a proportional increase
		// of the AutoHedge LP token
		uint256 currentUniLpBal = tokens.cUniLp.balanceOfUnderlying(address(this));
		uint256 increaseFactor = currentUniLpBal == 0
			? 0
			: (amountUniLp * BASE_FACTOR) / currentUniLpBal;
		address feeReceiver = fd.referrer;
		if (feeReceiver == address(0)) {
			feeReceiver = factory.feeReceiver();
		}
		// Mint AutoHedge LP tokens to the user. Need to do this after LPing so we know the exact amount of
		// assets that are LP'd with, but before affecting any of the borrowing so it simplifies those
		// calculations
		(, uint256 liquidityForUser) = _mintLiquidity(
			fd.to,
			feeReceiver,
			amountStable,
			amountVol,
			increaseFactor
		);
		// Use LP token as collateral
		uint256 code = tokens.cUniLp.mint(amountUniLp);
		require(code == 0, string(abi.encodePacked("AHV2: fuse LP mint ", Strings.toString(code))));
		// Borrow the volatile token
		code = tokens.cVol.borrow(amountVol);
		require(code == 0, string(abi.encodePacked("AHV2: fuse borrow ", Strings.toString(code))));
		// Repay the flashloan

		tokens.vol.safeTransfer(
			address(IFlashloanWrapper(factory.flw()).sushiBentoBox()),
			repayAmount
		);

		emit Deposited(
			fd.depositor,
			amountStable,
			amountVol,
			amountUniLp,
			amountsStableToVol[0],
			liquidityForUser
		);
	}

	function finishWithdraw(bytes calldata data)
		external
		override
		onlyFlw
		_updateBalanceOfUnderlyingTokens
		returns (uint256 amountStableToUser)
	{
		FinishWithdraw memory fw = abi.decode(data, (FinishWithdraw));
		uint256 fee = (fw.amountVolToFlashloan * FLASH_LOAN_FEE) / FLASH_LOAN_FEE_PRECISION;
		uint256 repayAmount = fw.amountVolToFlashloan + fee;
		uint256 code;

		// Repay the borrowed volatile depending on how much we have
		code = tokens.cVol.repayBorrow(fw.amountVolToFlashloan);

		require(
			code == 0,
			string(abi.encodePacked("AHV2: fuse vol repay ", Strings.toString(code)))
		);

		uint256 amountUniLp = (tokens.cUniLp.balanceOfUnderlying(address(this)) * fw.liquidity) /
			totalSupply;

		code = tokens.cUniLp.redeemUnderlying(amountUniLp);
		require(
			code == 0,
			string(abi.encodePacked("AHV2: fuse LP redeem 1 ", Strings.toString(code)))
		);

		(uint256 amountStableFromDex, uint256 amountVolFromDex) = uniV2Router.removeLiquidity(
			address(tokens.stable),
			address(tokens.vol),
			amountUniLp,
			0,
			0,
			address(this),
			MAX_UINT
		);

		// if we can't repay flashloan from the LP token withdrawal, swap some of the stable coins to vol
		if (amountVolFromDex < repayAmount) {
			address[] memory pathStableToVol = newPath(tokens.stable, tokens.vol);
			uniV2Router.swapTokensForExactTokens(
				repayAmount - amountVolFromDex,
				amountStableFromDex,
				pathStableToVol,
				address(this),
				MAX_UINT
			);
		} else if (amountVolFromDex > repayAmount) {
			address[] memory pathVolToStable = newPath(tokens.vol, tokens.stable);
			uniV2Router.swapExactTokensForTokens(
				amountVolFromDex - repayAmount,
				1,
				pathVolToStable,
				address(this),
				MAX_UINT
			);
		}

		tokens.vol.safeTransfer(
			address(IFlashloanWrapper(factory.flw()).sushiBentoBox()),
			repayAmount
		);

		amountStableToUser = tokens.stable.balanceOf(address(this));
		tokens.stable.safeTransfer(fw.to, amountStableToUser);

		_burn(fw.to, fw.liquidity);

		emit Withdrawn(fw.to, amountStableToUser, fw.amountVolToFlashloan, fw.liquidity);
	}

	/**
	 * @notice  Checks how much of the non-stablecoin asset we have being LP'd with on IDEX (amount X) and
	 *          how much debt we have in that asset at ILendingPlatform, and borrows/repays the debt to be equal to X,
	 *          if and only if the difference is more than 1%.
	 *          This function is what is automatically called by Autonomy.
	 */
	function rebalanceAuto(address user, uint256 feeAmount) public override nonReentrant {
		require(user == address(this), "AHV2: not user");
		require(msg.sender == userFeeVeriForwarder, "AHV2: not userFeeForw");
		_rebalance(feeAmount);
	}

	function rebalance(bool passIfInBounds) public nonReentrant {
		_rebalance(0);
	}

	function _rebalance(uint256 feeAmount) private _updateBalanceOfUnderlyingTokens {
		Tokens memory _tokens = tokens; // Gas savings
		VolPosition memory volPos = _getDebtBps(_tokens);
		// If there's ETH in this contract, then it's for the purpose of subsidising the
		// automation fee, and so we don't need to get funds from elsewhere to pay it
		bool payFeeFromBal = feeAmount <= address(this).balance;
		MmBps memory mb = mmBps;
		uint256 code;

		require(volPos.bps <= mb.min || volPos.bps >= mb.max, "AHV2: debt within range");

		// in case of price increased
		if (volPos.bps >= mb.max) {
			// Repay some debt
			address[] memory pathStableToVol = newPath(_tokens.stable, _tokens.vol);
			uint256 amountVolToRepay = volPos.debt - volPos.owned;
			uint256 amountStableEstimated = uniV2Router.getAmountsIn(
				amountVolToRepay + (payFeeFromBal ? 0 : feeAmount),
				pathStableToVol
			)[0];
			uint256 amountUniLpToWithdraw = (_tokens.uniLp.totalSupply() * amountStableEstimated) /
				_tokens.stable.balanceOf(address(_tokens.uniLp));

			code = tokens.cUniLp.redeemUnderlying(amountUniLpToWithdraw);
			require(
				code == 0,
				string(abi.encodePacked("AHV2: fuse LP redeem ", Strings.toString(code)))
			);

			(uint256 amountStableFromDex, uint256 amountVolFromDex) = uniV2Router.removeLiquidity(
				address(_tokens.stable),
				address(_tokens.vol),
				amountUniLpToWithdraw,
				0,
				0,
				address(this),
				MAX_UINT
			);

			amountVolFromDex += uniV2Router.swapExactTokensForTokens(
				amountStableFromDex,
				1,
				pathStableToVol,
				address(this),
				MAX_UINT
			)[1];

			if (feeAmount > 0 && !payFeeFromBal) {
				if (_tokens.vol == weth) {
					weth.safeTransfer(address(wu), feeAmount);
					wu.withdraw(feeAmount, address(registry));
					amountVolFromDex -= feeAmount;
				} else {
					address[] memory pathVolToWeth = newPath(_tokens.vol, weth);
					amountVolFromDex -= uniV2Router.swapTokensForExactETH(
						feeAmount,
						amountVolFromDex,
						pathVolToWeth,
						payable(address(registry)),
						MAX_UINT
					)[0];
				}
			}

			code = tokens.cVol.repayBorrow(amountVolFromDex);

			require(
				code == 0,
				string(abi.encodePacked("AHV2: fuse vol repay ", Strings.toString(code)))
			);
		} else {
			address[] memory pathVolToStable = newPath(_tokens.vol, _tokens.stable);
			// Borrow more
			uint256 amountVolDiff = volPos.owned - volPos.debt;
			// in case of diff amount is smaller than fee, we can just ignore that case as it's only possible
			// if 1% of LP is smaller than fee. But this is not possible as pool will not be that tiny.
			uint256 amountVolDiffExcess = amountVolDiff - (payFeeFromBal ? 0 : feeAmount);
			uint256 reserveVol = _tokens.vol.balanceOf(address(_tokens.uniLp));
			uint256 w = Maths.sqrt(reserveVol) *
				Maths.sqrt(reserveVol + amountVolDiffExcess * 4) -
				reserveVol;
			uint256 amountVolForStable = (1000 * w) / 2 / 997;
			uint256 amountVolToBorrow = amountVolDiffExcess +
				amountVolForStable +
				(payFeeFromBal ? 0 : feeAmount);

			code = _tokens.cVol.borrow(amountVolToBorrow);
			require(
				code == 0,
				string(abi.encodePacked("AHV2: fuse borrow more ", Strings.toString(code)))
			);

			if (feeAmount > 0 && !payFeeFromBal) {
				if (_tokens.vol == weth) {
					weth.safeTransfer(address(wu), feeAmount);
					wu.withdraw(feeAmount, address(registry));
					amountVolToBorrow -= feeAmount;
				} else {
					address[] memory pathVolToWeth = newPath(_tokens.vol, weth);
					// This 2nd swap to ETH would fail if there aren't enough stables to cover the execution
					// fee, but this is a feature not a bug - if only a small amount of tokens are being swapped,
					// then it's not worth paying for the rebalance, and it simplifies rebalancing
					amountVolToBorrow -= uniV2Router.swapTokensForExactETH(
						feeAmount,
						amountVolToBorrow,
						pathVolToWeth,
						payable(address(registry)),
						MAX_UINT
					)[0];
				}
			}

			uint256[] memory amountSwapped = uniV2Router.swapExactTokensForTokens(
				amountVolForStable,
				1,
				pathVolToStable,
				address(this),
				MAX_UINT
			);

			// There is a slight excess amount for stable and volatile tokens as we are swapping
			// before adding liquidity with the amounts estimated while the tokens are not swapped.
			(uint256 amountA, uint256 amountB, uint256 amountUniLp) = uniV2Router.addLiquidity(
				address(tokens.stable),
				address(tokens.vol),
				amountSwapped[1],
				amountVolToBorrow - amountSwapped[0],
				0,
				0,
				address(this),
				MAX_UINT
			);

			code = _tokens.cUniLp.mint(amountUniLp);
			require(
				code == 0,
				string(abi.encodePacked("AHV2: fuse LP mint ", Strings.toString(code)))
			);
		}

		if (feeAmount > 0 && payFeeFromBal) {
			payable(address(registry)).transfer(feeAmount);
		}

		volPos = _getDebtBps(_tokens);
		require(volPos.bps >= mb.min && volPos.bps <= mb.max, "AHV2: debt not within range");
	}

	function getDebtBps() public override returns (VolPosition memory) {
		return _getDebtBps(tokens);
	}

	function _getDebtBps(Tokens memory _tokens) private returns (VolPosition memory volPos) {
		volPos.owned =
			(_tokens.vol.balanceOf(address(_tokens.uniLp)) *
				_tokens.cUniLp.balanceOfUnderlying(address(this))) /
			_tokens.uniLp.totalSupply();
		volPos.debt = _tokens.cVol.borrowBalanceCurrent(address(this));
		volPos.bps = (volPos.debt * BASE_FACTOR) / volPos.owned;
	}

	function setMmBps(MmBps calldata newMmBps) external override onlyOwner {
		mmBps = newMmBps;
	}

	// function refreshBalanceOfUnderlyingTokens()
	// 	external
	// 	override
	// 	onlyOwner
	// 	_updateBalanceOfUnderlyingTokens
	// {}

	function _mintLiquidity(
		address to,
		address feeReceiver,
		uint256 amountStable,
		uint256 amountVol,
		uint256 increaseFactor
	) private returns (uint256 liquidityFee, uint256 liquidityForUser) {
		// (uint reserveStable, uint reserveVol, uint _totalSupply) = getReserves(amountStable, amountVol, amountUniLp);
		uint256 _totalSupply = totalSupply;
		uint256 liquidity;
		if (_totalSupply == 0) {
			liquidity = Maths.sqrt(amountStable * amountVol) - MINIMUM_LIQUIDITY;
			_mint(address(this), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
		} else {
			liquidity = (_totalSupply * increaseFactor) / BASE_FACTOR;
		}
		require(liquidity > 0, "AHV2: invalid liquidity mint");

		liquidityFee = (liquidity * factory.depositFee()) / BASE_FACTOR;
		liquidityForUser = liquidity - liquidityFee;

		_mint(feeReceiver, liquidityFee);
		_mint(to, liquidityForUser);
	}

	//////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////
	////                                                          ////
	////-------------------------Helpers--------------------------////
	////                                                          ////
	//////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////

	function newPath(IERC20Metadata src, IERC20Metadata dest)
		private
		pure
		returns (address[] memory)
	{
		address[] memory path = new address[](2);
		path[0] = address(src);
		path[1] = address(dest);
		return path;
	}

	function getTokens()
		external
		view
		override
		returns (
			IERC20Metadata stable,
			IERC20Metadata vol,
			ICErc20 cVol,
			IERC20Metadata uniLp,
			ICErc20 cUniLp
		)
	{
		Tokens memory _tokens = tokens;
		return (_tokens.stable, _tokens.vol, _tokens.cVol, _tokens.uniLp, _tokens.cUniLp);
	}

	receive() external payable {}

	/**
	 * @dev This empty reserved space is put in place to allow future versions to add new
	 * variables without shifting down storage in the inheritance chain.
	 * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
	 */
	uint256[50] private __gap;
}