// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

abstract contract ContractWhitelisted is AccessControlEnumerable {
	using EnumerableSet for EnumerableSet.AddressSet;

	bytes32 public constant whitelisterRole = keccak256('whitelister');

	// List of contracts that are able to interact with farm
	EnumerableSet.AddressSet private _whiteListOfContracts;

	modifier isAllowedContract(address _address) {
		if (Address.isContract(_address) || msg.sender != tx.origin) {
			require(isAddressOf(_address), 'Illegal, rejected ');
		}
		_;
	}

	/*
	 * @notice Adds address to whitelisted contracts list
	 * @param _address: Contract address to whitelist
	 */
	function addAddress(address _address)
		external
		onlyRole(whitelisterRole)
		returns (bool)
	{
		return _whiteListOfContracts.add(_address);
	}

	/*
	 * @notice Removes address from whitelisted contracts list
	 * @param _address: Contract address to remove from whitelist
	 */
	function delAddress(address _address)
		external
		onlyRole(whitelisterRole)
		returns (bool)
	{
		return _whiteListOfContracts.remove(_address);
	}

	function getAddressLength() public view returns (uint256) {
		return _whiteListOfContracts.length();
	}

	function isAddressOf(address _address) public view returns (bool) {
		return (_whiteListOfContracts.contains(_address));
	}

	function getAddress(uint256 index) public view returns (address) {
		require(index <= getAddressLength() - 1, 'index out of bounds');
		return _whiteListOfContracts.at(index);
	}
}