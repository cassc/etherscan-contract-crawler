pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../interface/IwTBTPoolV2Permission.sol";
import "../interface/ITBT.sol";

contract TBTHelper is AccessControl {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

	address public tbt;
	address public wtbt;
	IERC20 public underlyingToken;
	// recovery fund wallet
	address public recovery;

	constructor(address _tbt, address _wtbt, address _underlyingToken, address _recovery) {
		_setupRole(ADMIN_ROLE, msg.sender);
		tbt = _tbt;
		wtbt = _wtbt;
		underlyingToken = IERC20(_underlyingToken);
		require(_recovery != address(0), "!_recovery");
		recovery = _recovery;
	}

	/**
	 * @dev Mint wTBT
	 * @param amount the amout of underlying
	 */
	function mintWTBT(uint256 amount) external {
		address user = msg.sender;
		underlyingToken.safeTransferFrom(user, address(this), amount);
		underlyingToken.approve(wtbt, amount);
		IwTBTPoolV2Permission(wtbt).mintFor(amount, user);
	}

	/**
	 * @dev Mint TBT
	 * @param amount the amout of underlying
	 */
	function mintTBT(uint256 amount) external {
		address user = msg.sender;

		underlyingToken.safeTransferFrom(user, address(this), amount);

		underlyingToken.approve(wtbt, amount);

		uint256 _before = IERC20(wtbt).balanceOf(address(this));
		IwTBTPoolV2Permission(wtbt).mint(amount);
		uint256 _after = IERC20(wtbt).balanceOf(address(this));
		uint256 mintAmount = _after.sub(_before);

		IERC20(wtbt).approve(tbt, mintAmount);
		ITBT(tbt).unwrapFor(mintAmount, msg.sender);
	}

	/**
	 * @dev Allows to recover any ERC20 token
	 * @param recover Using to receive recovery of fund
	 * @param tokenAddress Address of the token to recover
	 * @param amountToRecover Amount of collateral to transfer
	 */
	function recoverERC20(
		address recover,
		address tokenAddress,
		uint256 amountToRecover
	) external onlyRole(ADMIN_ROLE) {
		IERC20(tokenAddress).safeTransfer(recover, amountToRecover);
	}
}