pragma solidity 0.8.6;

interface IWETHUnwrapper {
	function withdraw(uint256 amount, address to) external;
}