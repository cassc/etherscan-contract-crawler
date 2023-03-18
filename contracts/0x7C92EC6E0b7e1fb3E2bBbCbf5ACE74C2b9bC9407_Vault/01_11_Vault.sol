pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Vault is AccessControl {
	using SafeERC20 for IERC20;

	bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
	bytes32 public constant WTBTPOOL_ROLE = keccak256("WTBTPOOL_ROLE");
	bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

	// underlying token address
	IERC20 public underlying;
	// STBT token address
	IERC20 public stbt;
	// recovery fund wallet
	address public recovery;

	constructor(address _admin, address _underlying, address _stbt, address _recovery) {
		require(_admin != address(0), "!_admin");

		_setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
		_setupRole(DEFAULT_ADMIN_ROLE, _admin);
		_setupRole(ADMIN_ROLE, _admin);

		require(_underlying != address(0), "!_underlying");
		require(_recovery != address(0), "!_recovery");
		require(_stbt != address(0), "!_stbt");
		underlying = IERC20(_underlying);
		stbt = IERC20(_stbt);
		recovery = _recovery;
	}

	/**
	 * @dev Transfer a give amout of underlying to user
	 * @param user user address
	 * @param amount the amout of underlying
	 */
	function withdrawToUser(address user, uint256 amount) external onlyRole(WTBTPOOL_ROLE) {
		underlying.safeTransfer(user, amount);
	}

	/**
	 * @dev Transfer a give amout of stbt to matrixport's mint pool
	 * @param mpRedeemPool user address
	 * @param stbtAmount the amout of underlying
	 */
	function redeemSTBT(address mpRedeemPool, uint256 stbtAmount) external onlyRole(TREASURY_ROLE) {
		stbt.safeTransfer(mpRedeemPool, stbtAmount);
	}

	/**
	 * @dev Allows to recovery any ERC20 token
	 * @param tokenAddress Address of the token to recover
	 * @param amountToRecover Amount of collateral to transfer
	 */
	function recoverERC20(
		address tokenAddress,
		uint256 amountToRecover
	) external onlyRole(ADMIN_ROLE) {
		IERC20(tokenAddress).safeTransfer(recovery, amountToRecover);
	}
}