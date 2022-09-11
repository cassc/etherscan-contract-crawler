// SPDX-License-Identifier: CC0
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBlooomCollectionInitializer.sol";

contract BlooomCollectionFactory is Ownable {
	using Address for address;
	using Address for address payable;
	using Clones for address;
	// using Strings for uint256;

	/**
	 * @notice The address of the template all new collections will leverage.
	 */
	address public implementation;

	/**
	 * @notice The implementation version new collections will use.
	 * @dev This is auto-incremented each time the implementation is changed.
	 */
	// uint256 public version;

	event CollectionCreated(address indexed collectionContract, address indexed creator, uint256 nonce, string name, string symbol);

	// event ImplementationUpdated(address indexed implementation, uint256 indexed version);

	constructor() {}

	/**
	 * @notice Create a new collection contract.
	 * @param nonce An arbitrary value used to allow a creator to mint multiple collections.
	 * @dev The nonce is required and must be unique for the msg.sender + implementation version,
	 * otherwise this call will revert.
	 */
	function createCollection(
		uint256 nonce,
		string calldata name_,
		string calldata symbol_,
		uint32 maxSupply_,
		uint32 maxPerWallet_,
		uint64 price_,
		string calldata baseURI_
	) external returns (address) {
		require(bytes(symbol_).length > 0, "BlooomCollectionFactory: Symbol is required");

		// This reverts if the NFT was previously created using this implementation version + msg.sender + nonce
		address proxy = implementation.cloneDeterministic(_getSalt(msg.sender, nonce));

		IBlooomCollectionInitializer(proxy).initialize(payable(msg.sender), name_, symbol_, maxSupply_, maxPerWallet_, price_, baseURI_);

		emit CollectionCreated(proxy, msg.sender, nonce, name_, symbol_);

		// Returning the address created allows other contracts to integrate with this call
		return address(proxy);
	}

	/**
	 * @notice Returns the address of a collection given the current implementation version, creator, and nonce.
	 * This will return the same address whether the collection has already been created or not.
	 * @param nonce An arbitrary value used to allow a creator to mint multiple collections.
	 */
	function predictCollectionAddress(address creator, uint256 nonce) external view returns (address) {
		return implementation.predictDeterministicAddress(_getSalt(creator, nonce));
	}

	/**
	 * @notice Allows Foundation to change the collection implementation used for future collections.
	 * This call will auto-increment the version.
	 * Existing collections are not impacted.
	 */
	function adminUpdateImplementation(address _implementation) external onlyOwner {
		_updateImplementation(_implementation);
	}

	/**
	 * @dev Updates the implementation address, increments the version, and initializes the template.
	 * Since the template is initialized when set, implementations cannot be re-used.
	 * To downgrade the implementation, deploy the same bytecode again and then update to that.
	 */
	function _updateImplementation(address _implementation) private {
		require(_implementation.isContract(), "BlooomCollectionFactory: Implementation is not a contract");
		implementation = _implementation;
		// version++;

		// The implementation is initialized when assigned so that others may not claim it as their own.
		// ICollectionContractInitializer(_implementation).initialize(
		// 	payable(address(rolesContract)),
		// 	string(abi.encodePacked("Foundation Collection Template v", version.toString())),
		// 	string(abi.encodePacked("FCTv", version.toString()))
		// );

		// emit ImplementationUpdated(_implementation, version);
	}

	function _getSalt(address creator, uint256 nonce) private pure returns (bytes32) {
		return keccak256(abi.encodePacked(creator, nonce));
	}
}