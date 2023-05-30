// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVault.sol";
import "./libraries/SafeERC20.sol";

contract YearnProxy is Ownable {
	using SafeERC20 for IERC20;
	address private _feeReceiver;
	uint256 private _feeInBasisPoints;

	event FeePercentageUpdated(uint256 oldFeeInBasisPoints, uint256 newFeeInBasisPoints);

	event FeeReceiverUpdated(address oldFeeReceiver, address newFeeReceiver);

	event DepositWithFee(uint256 amountIn, uint256 amountWithoutFee, uint256 fee);

	constructor(address feeReceiver_, uint256 feeInBasisPoints_) {
		_feeReceiver = feeReceiver_;
		_feeInBasisPoints = feeInBasisPoints_;
	}

	function deposit(address vault, uint256 amount) external returns (uint256 shares) {
		address token = IVault(vault).token();
		IERC20 srcToken = IERC20(token);
		uint256 newAmount = deductFee(srcToken, amount);

		srcToken.approve(vault, newAmount);

		shares = IVault(vault).deposit(newAmount, msg.sender);
	}

	function deductFee(IERC20 token, uint256 amount) internal returns (uint256 newAmount) {
		uint256 fee = (amount * _feeInBasisPoints) / 10000;

		newAmount = amount - fee;

		token.safeTransferFrom(msg.sender, address(this), amount);
		token.safeTransfer(_feeReceiver, fee);

		emit DepositWithFee(amount, newAmount, fee);
	}

	function updateFeePercent(uint256 feeInBasisPoints_) external onlyOwner {
		uint256 oldFeeInBasisPoints = _feeInBasisPoints;
		_feeInBasisPoints = feeInBasisPoints_;

		emit FeePercentageUpdated(oldFeeInBasisPoints, _feeInBasisPoints);
	}

	function updateFeeReceiver(address feeReceiver_) external onlyOwner {
		address oldFeeReceiver = _feeReceiver;
		_feeReceiver = feeReceiver_;

		emit FeeReceiverUpdated(oldFeeReceiver, _feeReceiver);
	}
}