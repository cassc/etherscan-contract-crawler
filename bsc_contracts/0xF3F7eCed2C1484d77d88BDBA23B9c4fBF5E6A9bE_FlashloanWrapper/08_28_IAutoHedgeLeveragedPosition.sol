pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/ICErc20.sol";
import "../interfaces/IAutoHedgeStableVolatilePairUpgradeableV2.sol";
import "../interfaces/IFlashloanWrapper.sol";
import "../interfaces/IAutoHedgeLeveragedPositionFactory.sol";

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
		TokensLev tokens;
		uint256 amountStableDeposit;
		address referrer;
	}

	struct FinishWithdraw {
		TokensLev tokens;
		uint256 amountStableWithdraw;
		uint256 amountAhlpRedeem;
		uint256 amountVolToFlashloan;
		IAutoHedgeStableVolatilePairUpgradeableV2.FinishWithdraw pairFW;
	}

	event DepositLev(
		address indexed comptroller,
		address indexed pair,
		uint256 amountStableDeposit,
		uint256 amountStableFlashloan,
		uint256 leverageRatio
	);

	function initialize(IAutoHedgeLeveragedPositionFactory factory_) external;

	// function initiateDeposit(
	//     uint256 amount,
	//     uint256 fee,
	//     bytes calldata data
	// ) external;

	// function initiateWithdraw(
	//     uint256 amount,
	//     uint256 fee,
	//     bytes calldata data
	// ) external;
}