pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IComptroller.sol";
import "./IAutoHedgeStableVolatilePairUpgradeableV2.sol";

interface IAutoHedgeStableVolatileFactoryUpgradeableV2 {
	event PairCreated(
		IERC20Metadata indexed stable,
		IERC20Metadata indexed vol,
		address pair,
		uint256
	);
	event FeeReceiverSet(address indexed receiver);
	event DepositFeeSet(uint256 fee);

	function initialize(
		address beacon_,
		address weth_,
		IUniswapV2Factory uniV2Factory_,
		IUniswapV2Router02 uniV2Router_,
		IComptroller comptroller_,
		address payable registry_,
		address userFeeVeriForwarder_,
		IAutoHedgeStableVolatilePairUpgradeableV2.MmBps memory initMmBps_,
		address feeReceiver_,
		address flw_,
		address wu_
	) external;

	function flw() external view returns (address);

	function getPair(IERC20Metadata stable, IERC20Metadata vol)
		external
		view
		returns (address pair);

	function allPairs(uint256) external view returns (address pair);

	function allPairsLength() external view returns (uint256);

	function createPair(IERC20Metadata stable, IERC20Metadata vol) external returns (address pair);

	function setFeeReceiver(address newReceiver) external;

	function setDepositFee(uint256 newDepositFee) external;

	function uniV2Factory() external view returns (IUniswapV2Factory);

	function uniV2Router() external view returns (IUniswapV2Router02);

	function registry() external view returns (address payable);

	function userFeeVeriForwarder() external view returns (address);

	function feeReceiver() external view returns (address);

	function depositFee() external view returns (uint256);
}