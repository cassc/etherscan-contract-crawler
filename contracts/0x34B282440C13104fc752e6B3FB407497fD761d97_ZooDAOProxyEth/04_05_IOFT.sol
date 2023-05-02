// SPDX-License-Identifier: MIT

interface IOFT {
	function estimateSendFee(
		uint16 _dstChainId,
		bytes calldata _toAddress,
		uint256 _amount,
		bool _useZro,
		bytes calldata _adapterParams
	) external view returns (uint256 nativeFee, uint256 zroFee);

	function sendFrom(
		address _from,
		uint16 _dstChainId,
		bytes calldata _toAddress,
		uint256 _amount,
		address payable _refundAddress,
		address _zroPaymentAddress,
		bytes calldata _adapterParams
	) external payable;
}