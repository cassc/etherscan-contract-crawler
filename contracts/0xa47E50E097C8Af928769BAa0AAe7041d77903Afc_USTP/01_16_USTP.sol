// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Peg USD token for TProtocol.
 *
 */

contract USTP is ERC20, AccessControl {
	using SafeERC20 for ERC20;
	using SafeMath for uint256;

	ERC20 public rUSTP;

	constructor(address _admin, ERC20 _rUSTP) ERC20("USTP", "USTP") {
		_setupRole(DEFAULT_ADMIN_ROLE, _admin);
		rUSTP = _rUSTP;
	}

	/**
	 * @dev deposit rUSTP to USTP
	 * @param _amount the amount of USTP
	 */
	function deposit(uint256 _amount) external {
		// equal amount
		require(_amount > 0, "can't deposit zero rUSTP");
		rUSTP.safeTransferFrom(msg.sender, address(this), _amount);
		_mint(msg.sender, _amount);
	}

	/**
	 * @dev withdraw USTP to rUSTP
	 * @param _amount the amount of USTP
	 */
	function withdraw(uint256 _amount) external {
		require(_amount > 0, "can't withdraw zero rUSTP");
		_burn(msg.sender, _amount);
		rUSTP.safeTransfer(msg.sender, _amount);
	}

	/**
	 * @dev wrap all iUSTP to rUSTP
	 */
	function unWrapAll() external {
		uint256 userBalance = balanceOf(msg.sender);
		require(userBalance > 0, "can't wrap zero iUSTP");
		_burn(msg.sender, userBalance);

		rUSTP.safeTransfer(msg.sender, userBalance);
	}

	/**
	 * @dev Allows to recovery any ERC20 token
	 * @param tokenAddress Address of the token to recovery
	 * @param target Address for receive token
	 * @param amountToRecover Amount of collateral to transfer
	 */
	function recoverERC20(
		address tokenAddress,
		address target,
		uint256 amountToRecover
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(tokenAddress != address(rUSTP), "can't recover rUSTP");
		ERC20(tokenAddress).safeTransfer(target, amountToRecover);
	}

	/**
	 * @dev Allows to claim rUSTP
	 * @param target Address for receive token
	 */
	function claimUSTP(address target) external onlyRole(DEFAULT_ADMIN_ROLE) {
		uint256 totalDeposit = totalSupply();
		uint256 realLockAmount = rUSTP.balanceOf(address(this));
		uint256 claimAmount = realLockAmount - totalDeposit;
		require(claimAmount > 0, "no");
		rUSTP.safeTransfer(target, claimAmount);
	}
}