//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import './ReflectedNFT.sol';
import '@openzeppelin/contracts/proxy/Clones.sol';

/// @title ReflectionCreator - assisting contract to deploy ReflectedNFT
/// @author 0xslava
/// @notice Stores logic to deploy ReflectedNFT and record all required params
abstract contract ReflectionCreator {
	/// @notice Address of ReflectedNFT on network
	/// @dev For every bridged collection minimal proxy would be deployed with this implementation address
	address public implementation;

	/// @notice Returns ReflectedNFT address on current chain by original collection address as unique identifier
	/// @dev originalCollectionContract => reflectionCollectionContract
	// mapping(address => address) public reflection;
	/// @dev origChainId => originalCollectionContract => reflectionCollectionContract
	mapping(uint256 => mapping(address => address)) public reflection;

	/// @notice Returns if collection address on current chain is reflection (copy)
	/// @dev collectionAddr => isReflection
	mapping(address => bool) public isReflection;

	struct Origin {
		uint256 chainId;
		address collectionAddress;
	}
	/// @notice Returns original collection address by address of it's reflection (copy) on current chain
	/// @dev reflectionAddress => origCollAddr
	mapping(address => Origin) public origins;

	event NFTReflectionDeployed(address reflectionContractAddress, Origin origin);

	constructor(address _implementation) {
		// Sets address for ReflectedNFT implementation contract
		// To which minimal proxies will be delegate calling
		implementation = _implementation;
	}

	/// @notice Returns ReflectedNFT address from storage (if exists) or deploy new
	function _getReflectionAddress(
		Origin memory origin,
		string memory name,
		string memory symbol
	) internal returns (address reflectionAddr) {
		reflectionAddr = reflection[origin.chainId][origin.collectionAddress];
		bool reflectionDoesntExist = reflectionAddr == address(0);

		if (reflectionDoesntExist) {
			reflectionAddr = _deployReflection(origin, name, symbol);
		}
	}

	/// @notice Creates reflection (copy) of oringinal collection with original name and symbol
	/// @param origin chainId and original collection address
	/// @param name name of original collection to pass to ReflectedNFT
	/// @param symbol symbol of original collection to pass to ReflectedNFT
	/// @return _reflection - address of deployed ReflectedNFT contract
	function _deployReflection(
		Origin memory origin,
		string memory name,
		string memory symbol
	) internal returns (address _reflection) {
		_reflection = Clones.cloneDeterministic(implementation, keccak256(abi.encode(origin)));
		ReflectedNFT(_reflection).init(name, symbol);

		reflection[origin.chainId][origin.collectionAddress] = _reflection;
		isReflection[_reflection] = true;
		origins[_reflection] = origin;

		emit NFTReflectionDeployed(_reflection, origin);
	}

	function predictReflectionAddress(Origin memory origin) public view returns (address) {
		return Clones.predictDeterministicAddress(implementation, keccak256(abi.encode(origin)));
	}
}