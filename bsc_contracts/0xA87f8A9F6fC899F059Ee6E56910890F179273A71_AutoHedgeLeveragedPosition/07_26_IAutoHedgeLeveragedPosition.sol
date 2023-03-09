pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./IComptroller.sol";
import "./ICErc20.sol";
import "./IAutoHedgeStableVolatilePairUpgradeableV2.sol";
import "./IFlashloanWrapper.sol";
import "./IAutoHedgeLeveragedPositionFactory.sol";

interface IAutoHedgeLeveragedPosition {
	struct TokensLev {
		IERC20Metadata stable;
		ICErc20 cStable;
		IERC20Metadata vol;
		IAutoHedgeStableVolatilePairUpgradeableV2 pair;
		ICErc20 cAhlp;
	}

	struct FinishDeposit {
		IFlashloanWrapper.FinishRoute fr;
		uint256 amountStableDeposit;
		uint256 amountStableToFlashloan;
		address referrer;
		bool shouldReturnAmount;
		uint256 flashloanFee;
	}

	struct FinishWithdraw {
		IFlashloanWrapper.FinishRoute fr;
		uint256 amountAhlpRedeem;
		uint256 amountStableToFlashloan;
		bool shouldReturnAmount;
		uint256 flashloanFee;
	}

	event DepositLev(
		uint256 amountStableDeposit,
		uint256 amountStableFlashloan,
		uint256 amountStableFlashloanFee,
		uint256 leverageRatio
	);

	event WithdrawLev(
		uint256 amountAhlpRedeem,
		uint256 amountStableFlashloan,
		uint256 amountStableFlashloanFee
	);

	function initialize(
		IAutoHedgeLeveragedPositionFactory factory_,
		IComptroller comptroller,
		TokensLev memory tokens_
	) external;

	function finishDeposit(bytes calldata data) external;

	function finishWithdraw(bytes calldata data) external;
}