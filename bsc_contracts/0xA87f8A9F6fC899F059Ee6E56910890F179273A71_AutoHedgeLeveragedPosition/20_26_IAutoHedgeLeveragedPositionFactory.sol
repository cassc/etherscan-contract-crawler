pragma solidity 0.8.6;

import "./IComptroller.sol";
import "./IFlashloanWrapper.sol";
import "./IMasterPriceOracle.sol";
import "./IAutoHedgeLeveragedPosition.sol";

interface IAutoHedgeLeveragedPositionFactoryEvents {
	event LeveragedPositionCreated(address indexed creator, address indexed pair, address lvgPos);
	event FlashloanWrapperUpdated(address indexed flw);
	event OracleUpdated(address indexed oracle);
	event ComptrollerUpdated(address indexed comptroller);
}

interface IAutoHedgeLeveragedPositionFactory is IAutoHedgeLeveragedPositionFactoryEvents {
	function flw() external view returns (IFlashloanWrapper);

	function oracle() external view returns (IMasterPriceOracle);

	function comptroller() external view returns (IComptroller);

	function createLeveragedPosition(IAutoHedgeLeveragedPosition.TokensLev memory tokens_)
		external
		returns (address lvgPos);
}