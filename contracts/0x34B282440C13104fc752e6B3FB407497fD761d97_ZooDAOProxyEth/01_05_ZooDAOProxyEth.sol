// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IOFT.sol';

// Proxy contract to correctly interac with ProxtOFT
contract ZooDAOProxyEth is Ownable {
	address private _commissionReceiver;
	uint256 private _commissionAmountInNative;
	address public token;
	IOFT private proxyOft;

	event CommissionAmountUpdated(uint256 oldCommissionAmount, uint256 newCommissionAmount);

	event CommissionReceiverUpdated(address oldCommissionReceiver, address newCommissionReceiver);

	event BridgeWithCommission(uint256 amount, uint256 amountWithoutCommission, uint256 commission);

	constructor(
		address token_,
		address proxyOft_,
		address commisionReceiver_,
		uint256 commissionAmountInNative_
	) {
		_commissionReceiver = commisionReceiver_;
		_commissionAmountInNative = commissionAmountInNative_;

		token = token_;
		proxyOft = IOFT(proxyOft_);
	}

	function estimateSendFee(
		uint16 _dstChainId,
		bytes calldata _toAddress,
		uint256 _amount,
		bool _useZro,
		bytes calldata _adapterParams
	) public view returns (uint256 nativeFee, uint256 zroFee) {
		(nativeFee, zroFee) = proxyOft.estimateSendFee(_dstChainId, _toAddress, _amount, _useZro, _adapterParams);
		nativeFee += _commissionAmountInNative;
	}

	function sendFrom(
		address,
		uint16 _dstChainId,
		bytes calldata _toAddress,
		uint256 _amount,
		address payable _refundAddress,
		address _zroPaymentAddress,
		bytes calldata _adapterParams
	) public payable {
		require(IERC20(token).transferFrom(msg.sender, address(this), _amount));
		require(IERC20(token).approve(address(proxyOft), _amount));

		uint256 newValue = deductCommissionInNative();
		proxyOft.sendFrom{value: newValue}(
			address(this),
			_dstChainId,
			_toAddress,
			_amount,
			_refundAddress,
			_zroPaymentAddress,
			_adapterParams
		);
	}

	function deductCommissionInNative() internal returns (uint256 newFeeAmount) {
		(bool success, ) = _commissionReceiver.call{value: _commissionAmountInNative}('');
		require(success, 'Fee is too low. Get fee amount from estimateSendFee()');

		emit BridgeWithCommission(msg.value, msg.value - _commissionAmountInNative, _commissionAmountInNative);

		return msg.value - _commissionAmountInNative;
	}

	function updateCommissionAmount(uint256 commissionAmountInNative_) external onlyOwner {
		uint256 oldCommissionAmountInNative = _commissionAmountInNative;
		_commissionAmountInNative = commissionAmountInNative_;

		emit CommissionAmountUpdated(oldCommissionAmountInNative, _commissionAmountInNative);
	}

	function updateCommissionReceiver(address commisionReceiver_) external onlyOwner {
		address oldCommissionReceiver = _commissionReceiver;
		_commissionReceiver = commisionReceiver_;

		emit CommissionReceiverUpdated(oldCommissionReceiver, _commissionReceiver);
	}
}