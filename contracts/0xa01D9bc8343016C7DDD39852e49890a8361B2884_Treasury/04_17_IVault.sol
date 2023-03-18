pragma solidity ^0.8.0;

interface IVault {
	function withdrawToUser(address, uint256) external;

	function recoverERC20(address, uint256) external;

	function redeemSTBT(address, uint256) external;
}