// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IUsingStorage {
	function getStorageAddress() external view returns (address);

	function createStorage() external;

	function setStorage(address _storageAddress) external;

	function changeOwner(address newOwner) external;
}