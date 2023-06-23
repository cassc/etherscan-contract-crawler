// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/universal-router/contracts/interfaces/IUniversalRouter.sol";
import "./libraries/SafeERC20.sol";
import "./interfaces/IPermit2.sol";

contract SwapProxy is Ownable {
	IUniversalRouter public router;

	address public feeReceiver;
	uint256 public feeInBasisPoints;

	address public permit;

	using SafeERC20 for IERC20;

	event FeePercentageUpdated(uint256 oldFeeInBasisPoints, uint256 newFeeInBasisPoints);

	event FeeReceiverUpdated(address oldFeeReceiver, address newFeeReceiver);

	constructor(
		address router_,
		address permit_,
		address feeReceiver_,
		uint256 feeInBasisPoints_
	) {
		router = IUniversalRouter(router_);

		permit = permit_;

		feeReceiver = feeReceiver_;
		feeInBasisPoints = feeInBasisPoints_;
	}

	/// @notice Executes swap on Uniswap UniversalRouter
	/// @dev swap params must already changed to be without fee amount
	/// @dev optimized version with off-chain calculation
	function execute(
		bool swapsNativeCurrency,
		address inputToken,
		uint256 amount,
		bytes calldata commands,
		bytes[] memory inputs,
		uint256 deadline
	) public payable {
		if (swapsNativeCurrency) {
			uint256 fee = deductEthFee();
			router.execute{value: msg.value - fee}(commands, inputs, deadline);
		} else {
			deductFee(inputToken, amount);
			router.execute(commands, inputs, deadline);
		}
	}

	function deductFee(address srcToken, uint256 amount) internal {
		uint256 fee = (amount * feeInBasisPoints) / 10000;
		IERC20 token = IERC20(srcToken);

		token.safeTransferFrom(msg.sender, address(this), amount);
		token.safeTransfer(feeReceiver, fee);
		token.safeIncreaseAllowance(address(permit), amount - fee);

		// Approval to spend from Permit allowance to pool/router?
		IPermit2(permit).approve(srcToken, address(router), uint160(amount - fee), uint48(block.timestamp + 5000));
	}

	function deductEthFee() internal returns (uint256 fee) {
		fee = (msg.value * feeInBasisPoints) / 10000;

		(bool success, ) = feeReceiver.call{value: fee}("");
		require(success, "Transfer to receiver failed");
	}

	function updateFeePercent(uint256 feeInBasisPoints_) external onlyOwner {
		uint256 oldFeeInBasisPoints = feeInBasisPoints;
		feeInBasisPoints = feeInBasisPoints_;

		emit FeePercentageUpdated(oldFeeInBasisPoints, feeInBasisPoints);
	}

	function updateFeeReceiver(address feeReceiver_) external onlyOwner {
		address oldFeeReceiver = feeReceiver;
		feeReceiver = feeReceiver_;

		emit FeeReceiverUpdated(oldFeeReceiver, feeReceiver);
	}
}