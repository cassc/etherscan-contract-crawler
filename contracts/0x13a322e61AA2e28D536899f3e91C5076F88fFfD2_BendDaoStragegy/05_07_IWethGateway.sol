pragma solidity ^0.8.2;

interface IWethGateway {
	function depositETH(address onBehalfOf, uint16 referralCode) external payable;
	function withdrawETH(uint256 amount, address to) external;
}