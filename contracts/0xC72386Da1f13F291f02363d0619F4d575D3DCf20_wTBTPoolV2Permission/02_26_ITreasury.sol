pragma solidity ^0.8.0;

interface ITreasury {
	function getRedeemAmountOutFromCurve(uint256, int128) external view returns (uint256);

	function setRedeemPool(address) external;

	function setMintPool(address) external;

	function setMintThreshold(uint256) external;

	function setRedeemThreshold(uint256) external;

	function mintSTBT() external;

	function redeemSTBT(uint256) external;

	function redeemSTBTByCurveWithFee(
		uint256 amount,
		int128 j,
		uint256 minReturn,
		address receiver,
		uint256 feeRate,
		uint256 feeCoefficient,
		address feeCollector
	) external;

	function redeemAllSTBT() external;

	function claimManagementFee(address, uint256) external;

	function recoverERC20(address, uint256) external;
}