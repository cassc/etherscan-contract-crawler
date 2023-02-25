//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICollectionDeployer {
	function deploy(
		string memory name_,
		string memory symbol_,
		address _creator,
		address _addressesStorage
	) external returns (address);
}