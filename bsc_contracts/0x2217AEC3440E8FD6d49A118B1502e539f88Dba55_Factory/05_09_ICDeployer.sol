pragma solidity >=0.5.0;

interface ICDeployer {
	function deployCollateral(address uniswapV2Pair) external returns (address collateral);
}