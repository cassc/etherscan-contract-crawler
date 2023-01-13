//SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <=0.6.12;
pragma experimental ABIEncoderV2;

interface ISushiLPtoCurveLPMigration {
	struct SushiWithdrawalInfo {
		uint256 amountLp;
		uint256 amountTokeMin;
		uint256 amountWethMin;
		uint256 deadline;
	}

	event SushiLPtoCurveLPMigrationEvent(
		uint256 amountSushiLpBurned,
		uint256 amountCurveLpMinted,
		uint256 amountTokeWithdrawnFromSushi,
		uint256 amountWethWithdrawnFromSushi
	);

	/// @notice Withdraw amount of SUSHI LP token and deposit returned TOKE and WETH to CURVE pool.
	/// @notice Send CURVE LP back to the user.
	/// @param withdrawalInfo sushi pool withdrawal infos
	/// @param amountCurveLpMin minimum amount of Curve LP token to receive
	function migrate(
		SushiWithdrawalInfo calldata withdrawalInfo,
		uint256 amountCurveLpMin,
		address to
	) external;
}