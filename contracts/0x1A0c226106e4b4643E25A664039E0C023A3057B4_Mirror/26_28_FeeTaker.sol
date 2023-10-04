//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

contract FeeTaker is Ownable {
	address private _feeReceiver;
	uint256 public feeAmount;

	event FeeAmountUpdated(uint256 oldFeeInBasisPoints, uint256 newFeeInBasisPoints);

	event FeeReceiverUpdated(address oldFeeReceiver, address newFeeReceiver);

	constructor(uint256 feeAmount_, address feeReceiver_) {
		updateFeeAmount(feeAmount_);
		updateFeeReceiver(feeReceiver_);
	}

	function _deductFee() internal {
		(bool success, ) = _feeReceiver.call{value: feeAmount}('');
		require(success, 'Transfer to receiver failed');
	}

	function updateFeeAmount(uint256 feeAmount_) public onlyOwner {
		uint256 oldFeeAmount = feeAmount;
		feeAmount = feeAmount_;

		emit FeeAmountUpdated(oldFeeAmount, feeAmount);
	}

	function updateFeeReceiver(address feeReceiver_) public onlyOwner {
		address oldFeeReceiver = _feeReceiver;
		_feeReceiver = feeReceiver_;

		emit FeeReceiverUpdated(oldFeeReceiver, _feeReceiver);
	}
}