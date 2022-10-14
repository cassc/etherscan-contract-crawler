// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./RewardVaultStorage.sol";

contract RewardVault is RewardVaultStorage {

	event NewImplementation(address newImplementation);

	function setImplementation(address newImplementation) external _onlyAdmin_ {
		implementation = newImplementation;
		emit NewImplementation(newImplementation);
	}

	fallback() external payable {
		_delegate();
	}

	receive() external payable {

	}

	function _delegate() internal {
		address imp = implementation;
		assembly {
			calldatacopy(0, 0, calldatasize())
			let result := delegatecall(gas(), imp, 0, calldatasize(), 0, 0)
			returndatacopy(0, 0, returndatasize())
			switch result
			case 0 {revert(0, returndatasize())}
			default {return (0, returndatasize())}
		}
	}


}