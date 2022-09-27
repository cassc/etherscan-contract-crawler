// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ProxyStorage {

	address public otherContractAddress;

	function setOtherAddressStorage(address _otherContract) internal {
		otherContractAddress = _otherContract;
	}
}