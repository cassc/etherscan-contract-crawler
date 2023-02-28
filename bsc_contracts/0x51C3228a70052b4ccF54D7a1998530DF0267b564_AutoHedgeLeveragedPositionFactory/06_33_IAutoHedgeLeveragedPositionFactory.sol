pragma solidity 0.8.6;

import "./IComptroller.sol";
import "./IFlashloanWrapper.sol";
import "./IMasterPriceOracle.sol";
import "./IAutoHedgeLeveragedPosition.sol";

interface IAutoHedgeLeveragedPositionFactory {
	event LeveragedPositionCreated(address indexed creator, address indexed pair, address lvgPos);

	function flw() external view returns (IFlashloanWrapper);

	function oracle() external view returns (IMasterPriceOracle);

	function createLeveragedPosition(
		IComptroller comptroller,
		IAutoHedgeLeveragedPosition.TokensLev memory tokens_
	) external returns (address lvgPos);
}