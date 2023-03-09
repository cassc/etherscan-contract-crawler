pragma solidity 0.8.6;

interface IMasterPriceOracle {
	function price(address underlying) external returns (uint256);
}