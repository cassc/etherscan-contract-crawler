pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IAutoHedgeLeveragedPosition.sol";
import "../interfaces/IAutoHedgeStableVolatileFactoryUpgradeableV2.sol";
import "../interfaces/IFinisher.sol";
import "../interfaces/IFlashloanWrapper.sol";
import "../interfaces/IMasterPriceOracle.sol";

contract AutoHedgeLeveragedPosition is
	Initializable,
	OwnableUpgradeable,
	ReentrancyGuardUpgradeable,
	IAutoHedgeLeveragedPosition
{
	function initialize(
		IAutoHedgeLeveragedPositionFactory factory_,
		IComptroller comptroller_,
		TokensLev memory tokens_
	) external override initializer {
		__Ownable_init_unchained();
		factory = factory_;
		tokens = tokens_;
		comptroller = comptroller_;

		// Enter the relevant markets on Fuse/Midas

		address[] memory cTokens = new address[](2);
		cTokens[0] = address(tokens.cStable);
		cTokens[1] = address(tokens.cAhlp);

		uint256[] memory results = comptroller.enterMarkets(cTokens);
		require(
			results[0] == 0 && results[1] == 0,
			string(
				abi.encodePacked(
					"AHLevPos: cant enter markets: ",
					Strings.toString(results[0]),
					" ",
					Strings.toString(results[1])
				)
			)
		);

		IERC20Metadata(address(tokens.pair)).approve(address(tokens.cAhlp), MAX_UINT);
		tokens.stable.approve(address(tokens.cStable), MAX_UINT);
	}

	using SafeERC20 for IERC20Metadata;

	uint256 private constant BASE_FACTOR = 1e18;
	uint256 private constant MAX_UINT = type(uint256).max;

	IAutoHedgeLeveragedPositionFactory public factory;

	IComptroller private comptroller;

	TokensLev private tokens;

	modifier onlyFlw() {
		require(msg.sender == address(factory.flw()), "AHLev: caller is not flw");
		_;
	}

	/// @dev Estimate flashloan amount for deposit
	/// @param amountStableInit Amount of stable token to deposit
	/// @param leverageRatio Leverage ratio (18 decimals precision)
	/// @param pair Address of the AH pair
	/// @return amountStableToFlashloan Amount of stable token to flashloan
	/// @return amountStableFlashloanFee Amount of stable token flashloan fee
	function estimateFlashloanAmountForDeposit(
		uint256 amountStableInit,
		uint256 leverageRatio,
		address pair
	) private returns (uint256 amountStableToFlashloan, uint256 amountStableFlashloanFee) {
		IFlashloanWrapper flw = IFlashloanWrapper(factory.flw());

		uint256 flashLoanFee = flw.FLASH_LOAN_FEE();
		uint256 flashLoanFeePrecision = flw.FLASH_LOAN_FEE_PRECISION();

		IAutoHedgeStableVolatileFactoryUpgradeableV2 ahFactory = IAutoHedgeStableVolatilePairUpgradeableV2(
				pair
			).factory();

		// 18 decimals precision
		uint256 depositFee = ahFactory.depositFee();

		uint256 ahConvRate = 1 ether - depositFee;

		uint256 q = (amountStableInit * ahConvRate * (leverageRatio - 1 ether)) / 1 ether;

		uint256 r = (leverageRatio *
			(1 ether + (flashLoanFee * 1 ether) / flashLoanFeePrecision - ahConvRate)) /
			1 ether +
			ahConvRate;

		amountStableToFlashloan = q / r;
		amountStableFlashloanFee = (amountStableToFlashloan * flashLoanFee) / flashLoanFeePrecision;
	}

	/**
	 * @param amountStableDeposit   The amount of stables taken from the user
	 * The amount of stables to borrow from a flashloan which
	 *      is used to deposit (along with `amountStableDeposit`) to AH. Since there
	 *      is a fee for taking out a flashloan and depositing to AH, that's paid by
	 *      borrowing more stables, which therefore increases the leverage ratio. In
	 *      order to compensate for this, we need to have a reduced flashloan which
	 *      therefore lowers the total position size. Given `amountStableDeposit` and
	 *      the desired leverage ratio, we can calculate `amountStableFlashloan`
	 *      with these linear equations:
	 *          The flashloan fee is a % of the loan
	 *          (a) amountFlashloanFee = amountStableFlashloan*flashloanFeeRate
	 *
	 *          The value of the AH LP tokens after depositing is the total amount deposited,
	 *          which is the initial collateral and the amount from the flashloan, multiplied by
	 *          the amount that is kept after fees/costs
	 *          (b) amountStableAhlp = (amountStableDeposit + amountStableFlashloan)*ahConvRate
	 *
	 *          The amount being borrowed from Fuse needs to be enough to pay back the flashloan
	 *          and its fee
	 *          (c) amountStableBorrowed = amountStableFlashloan + amountFlashloanFee
	 *
	 *          The leverage ratio is the position size div by the 'collateral', i.e. how
	 *          much the user would be left with after withdrawing everything.
	 *          TODO: 'collateral' currently doesn't account for the flashloan fee when withdrawing
	 *          (d) leverage = amountStableAhlp / (amountStableAhlp - amountStableBorrowed)
	 *
	 *      Subbing (a) into (c):
	 *          (e) amountStableBorrowed = amountStableFlashloan + amountStableFlashloan*flashloanFeeRate
	 *          (f) amountStableBorrowed = amountStableFlashloan*(1 + flashloanFeeRate)
	 *          (g) amountStableFlashloan = amountStableBorrowed/(1 + flashloanFeeRate)
	 *
	 *      Rearranging (d):
	 *          (h) amountStableAhlp - amountStableBorrowed = amountStableAhlp/leverage
	 *          (i) amountStableBorrowed = amountStableAhlp*(1 - (1/leverage))
	 *
	 *      Subbing (i) into (g):
	 *          (j) amountStableFlashloan = (amountStableAhlp * (1 - (1/leverage))) / (1 + flashloanFeeRate)
	 *
	 *      Subbing (b) into (j):
	 *          (k) amountStableFlashloan = (((amountStableDeposit + amountStableFlashloan)*ahConvRate) * (1 - (1/leverage))) / (1 + flashloanFeeRate)
	 *      Rearranging, the general formula for `amountStableFlashloan` is:
	 *          (l) amountStableFlashloan = -(amountStableDeposit * ahConvRate * (leverage - 1)) / (ahConvRate * (leverage - 1) - leverage * (flashloanFeeRate + 1))
	 *
	 *      E.g. if amountStableDeposit = 10, ahConvRate = 0.991, leverage = 5, flashloanFeeRate = 0.0005
	 *          amountStableFlashloan = -(10 * 0.991 * (5 - 1)) / (0.991 * (5 - 1) - 5 * (0.0005 + 1))
	 *          amountStableFlashloan = 37.71646...
	 * @param leverageRatio The leverage ratio scaled to 1e18. Used to check that the leverage
	 *      is what is intended at the end of the fcn. E.g. if wanting 5x leverage, this should
	 *      be 5e18.
	 */
	function depositLev(
		address referrer,
		uint256 amountStableDeposit,
		uint256 leverageRatio
	) external onlyOwner nonReentrant {
		transferApproveUnapproved(address(tokens.pair), tokens.stable, amountStableDeposit);

		(uint256 amountStableToFlashloan, uint256 flashloanFee) = estimateFlashloanAmountForDeposit(
			amountStableDeposit,
			leverageRatio,
			address(tokens.pair)
		);

		IFlashloanWrapper.FinishRoute memory fr = IFlashloanWrapper.FinishRoute(
			address(this),
			address(this)
		);

		FinishDeposit memory fd = FinishDeposit(
			fr,
			amountStableDeposit,
			amountStableToFlashloan,
			referrer,
			0
		);

		// Take out a flashloan for the amount that needs to be borrowed
		bytes memory data = abi.encodeWithSelector(
			IAutoHedgeLeveragedPosition.finishDeposit.selector,
			abi.encode(fd)
		);
		IFlashloanWrapper flw = factory.flw();
		flw.takeOutFlashLoan(tokens.stable, amountStableToFlashloan, data);

		tokens.stable.safeTransfer(msg.sender, tokens.stable.balanceOf(address(this)));

		// // TODO: Some checks requiring that the positions are what they should be everywhere
		// // TODO: Check that the collat ratio is above some value
		// // TODO: Do these checks on withdrawLev too
		emit DepositLev(amountStableDeposit, amountStableToFlashloan, flashloanFee, leverageRatio);
	}

	function finishDeposit(bytes calldata data) public override onlyFlw {
		FinishDeposit memory fd = abi.decode(data, (FinishDeposit));

		uint256 repayAmount = fd.amountStableToFlashloan + fd.flashloanFee;
		uint256 amountStable = fd.amountStableDeposit + fd.amountStableToFlashloan;

		approveUnapproved(address(tokens.pair), tokens.stable, amountStable);

		IFlashloanWrapper flw = factory.flw();

		tokens.pair.deposit(amountStable, address(this), fd.referrer);

		// Put all AHLP tokens as collateral
		uint256 ahlpBal = IERC20Metadata(address(tokens.pair)).balanceOf(address(this));
		uint256 code = tokens.cAhlp.mint(ahlpBal);
		require(
			code == 0,
			string(abi.encodePacked("AHLevPos: fuse mint ", Strings.toString(code)))
		);

		// Borrow the same amount of stables from Fuse/Midas as was borrowed in the flashloan
		// TODO: call approve on cStable
		approveUnapproved(address(tokens.cStable), tokens.stable, repayAmount);
		code = tokens.cStable.borrow(repayAmount);
		require(
			code == 0,
			string(abi.encodePacked("AHLevPos: fuse borrow ", Strings.toString(code)))
		);

		tokens.stable.safeTransfer(address(flw.sushiBentoBox()), repayAmount);
	}

	function estimateFlashloanAmountForWithdraw(uint256 amountAhlpRedeem)
		private
		returns (uint256 amountStableToFlashloan, uint256 amountStableFlashloanFee)
	{
		IFlashloanWrapper flw = IFlashloanWrapper(factory.flw());

		uint256 amountAhlpUnderlying = tokens.cAhlp.balanceOfUnderlying(address(this));
		uint256 amountStableOwed = tokens.cStable.borrowBalanceCurrent(address(this));
		amountStableToFlashloan = (amountStableOwed * amountAhlpRedeem) / amountAhlpUnderlying;

		uint256 flashLoanFee = flw.FLASH_LOAN_FEE();
		uint256 flashLoanFeePrecision = flw.FLASH_LOAN_FEE_PRECISION();

		amountStableFlashloanFee = (amountStableToFlashloan * flashLoanFee) / flashLoanFeePrecision;
	}

	/**
	 * @param amountAhlpRedeem The amount of stables to borrow from a flashloan and
	 *      repay the Fuse/Midas debt. This needs to account for the flashloan fee in
	 *      order to not increase the overall leverage level of the position. For example
	 *      if leverage is 10x and withdrawing $10 of stables to the user, means
	 *      withdrawing $100 of AHLP tokens, which means needing to flashloan borrow
	 *      $90 of stables - which has a fee of $0.27 if the fee is 0.3%. Therefore
	 *      `amountStableRepay` needs to be $90 / 0.997 = 90.2708... to account for
	 *      paying the $0.27 and then the extra $0.0008... for the fee on the $0.27 etc.
	 */
	function withdrawLev(uint256 amountAhlpRedeem) external onlyOwner nonReentrant {
		(
			uint256 amountStableToFlashloan,
			uint256 flashloanFee
		) = estimateFlashloanAmountForWithdraw(amountAhlpRedeem);

		IFlashloanWrapper.FinishRoute memory fr = IFlashloanWrapper.FinishRoute(
			address(this),
			address(this)
		);

		FinishWithdraw memory fw = FinishWithdraw(fr, amountAhlpRedeem, amountStableToFlashloan, 0);

		// Take a flashloan for the amount that needs to be borrowed
		bytes memory data = abi.encodeWithSelector(
			IAutoHedgeLeveragedPosition.finishWithdraw.selector,
			abi.encode(fw)
		);
		IFlashloanWrapper flw = factory.flw();
		flw.takeOutFlashLoan(tokens.stable, amountStableToFlashloan, data);

		emit WithdrawLev(amountAhlpRedeem, amountStableToFlashloan, flashloanFee);
	}

	function finishWithdraw(bytes calldata data) public override onlyFlw {
		FinishWithdraw memory fw = abi.decode(data, (FinishWithdraw));

		uint256 repayAmount = fw.amountStableToFlashloan + fw.flashloanFee;

		// Repay borrowed stables in Fuse to free up collat
		uint256 code = tokens.cStable.repayBorrow(fw.amountStableToFlashloan);
		require(
			code == 0,
			string(abi.encodePacked("AHLevPos: fuse repayBorrow ", Strings.toString(code)))
		);
		// Take the AHLP collat out of Fuse/Midas
		code = tokens.cAhlp.redeemUnderlying(fw.amountAhlpRedeem);
		require(
			code == 0,
			string(abi.encodePacked("AHLevPos: fuse redeemUnderlying ", Strings.toString(code)))
		);

		IFlashloanWrapper flw = factory.flw();

		tokens.pair.withdraw(fw.amountAhlpRedeem, address(this));
		uint256 amountStablesFromAhlp = tokens.stable.balanceOf(address(this));
		require(
			amountStablesFromAhlp >= repayAmount,
			"AHLevPos: withdrawal amount is less than flashloan"
		);
		// Repay the flashloan
		tokens.stable.safeTransfer(address(flw.sushiBentoBox()), repayAmount);

		// Send the user their #madgainz
		tokens.stable.safeTransfer(owner(), amountStablesFromAhlp - repayAmount);
	}

	// fcns to withdraw tokens incase of liquidation

	//////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////
	////                                                          ////
	////-------------------------Helpers--------------------------////
	////                                                          ////
	//////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////

	function approveUnapproved(
		address target,
		IERC20Metadata token,
		uint256 amount
	) private {
		if (token.allowance(address(this), address(target)) < amount) {
			token.approve(address(target), MAX_UINT);
		}
	}

	function transferApproveUnapproved(
		address target,
		IERC20Metadata token,
		uint256 amount
	) private {
		approveUnapproved(target, token, amount);
		token.safeTransferFrom(msg.sender, address(this), amount);
	}

	function getFeeFactor() external view returns (uint256) {
		IFlashloanWrapper flw = factory.flw();
		return flw.getFeeFactor();
	}
}