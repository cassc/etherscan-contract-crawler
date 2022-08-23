// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IFeeRegistry {
	function totalFees() external view returns (uint256);

	function multisigPart() external view returns (uint256);

	function accumulatorPart() external view returns (uint256);

	function veSDTPart() external view returns (uint256);

	function maxFees() external view returns (uint256);

	function feeDenominator() external view returns (uint256);

	function multiSig() external view returns (address);

	function accumulator() external view returns (address);

	function veSDTFeeProxy() external view returns (address);

	function setOwner(address _address) external;

	function setFees(
		uint256 _multi,
		uint256 _accumulator,
		uint256 _veSDT
	) external;

	function setMultisig(address _multi) external;

	function setAccumulator(address _accumulator) external;

	function setVeSDTFeeProxy(address _feeProxy) external;
}