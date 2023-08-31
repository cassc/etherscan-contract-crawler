//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import '@openzeppelin/contracts/access/Ownable.sol';
import './ReflectionCreator.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@layerzerolabs/solidity-examples/contracts/token/onft/ONFT721Core.sol';
import '@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol';
import './FeeTaker.sol';

/// @title NFT bridge named Mirror
/// @author 0xslava
/// @notice Mirror bridges NFTs to other supported chains
/// @notice Bridge process named "creating reflection"
/// @notice Copy of NFT collections are called "reflections"
/// @notice Can reflect only eligible NFT collections
/// @notice Can reflect NFT to any chain, where Mirror contracts exists and connnected
/// @dev When collection bridged from source to target chain for the first time - deploys ReflectedNFT contract
/// @dev If collection was already bridged to target chain before - uses existing ReflectedNFT contract
/// @dev For creating ReflectedNFT contracts uses original collection's name and symbol
contract Mirror is NonblockingLzApp, ReflectionCreator, FeeTaker, IERC721Receiver {
	/// @notice Limit for amount of tokens being bridged in single transaction
	uint256 public reflectionAmountLimit = 10;

	/// @dev Used in createReflection() and _reflect() functions to determine if collection address is original for that chain
	mapping(address => bool) public isOriginalChainForCollection;

	/// @notice Checks if collection eligible to bridge
	mapping(address => bool) public isEligibleCollection;

	/* EVENTS */
	/// @dev Triggered on NFT being transfered from user to lock it on contract if collection is original
	event NFTReceived(address operator, address from, uint256 tokenId, bytes data);

	/// @dev Triggered in the end of the every bridge of token-reflection
	event NFTBridged(address originalCollectionAddress, uint256[] tokenIds, string[] tokenURIs, address owner);

	/// @dev Triggered when NFT unlocked from contract and returned to owner
	event NFTReturned(address originalCollectionAddress, uint256[] tokenIds, address owner);

	/// @dev Triggered at the start of every bridge process
	event BridgeNFT(
		address collection,
		string name,
		string symbol,
		uint256[] tokenId,
		string[] tokenURI,
		address owner
	);

	constructor(
		address _lzEndpoint,
		uint256 _feeAmount,
		address _feeReceiver
	) NonblockingLzApp(_lzEndpoint) FeeTaker(_feeAmount, _feeReceiver) {}

	/// @notice Estimates fee needed to bridge signle token to target chain
	function estimateSendFee(
		address collection,
		uint tokenId,
		uint16 targetNetworkId,
		bool useZro,
		bytes memory adapterParams
	) public view returns (uint nativeFee, uint zroFee) {
		return estimateSendBatchFee(collection, _toSingletonArray(tokenId), targetNetworkId, useZro, adapterParams);
	}

	/// @notice Estimates fee needed to bridge batch of tokens to target chain
	function estimateSendBatchFee(
		address collectionAddr,
		uint[] memory tokenIds,
		uint16 targetNetworkId,
		bool useZro,
		bytes memory adapterParams
	) public view returns (uint nativeFee, uint zroFee) {
		ReflectedNFT collection = ReflectedNFT(collectionAddr);

		string memory name = collection.name();
		string memory symbol = collection.symbol();

		string[] memory tokenURIs = new string[](tokenIds.length);

		for (uint256 i = 0; i < tokenIds.length; i++) {
			string memory tokenURI = collection.tokenURI(tokenIds[i]);
			tokenURIs[i] = tokenURI;
		}

		bytes memory payload = abi.encode(collection, name, symbol, tokenIds, tokenURIs, msg.sender);

		(nativeFee, zroFee) = lzEndpoint.estimateFees(targetNetworkId, address(this), payload, useZro, adapterParams);
		nativeFee += feeAmount;
	}

	/// @notice Bridges NFT to target chain
	/// @notice Locks original NFT on contract before bridge
	/// @notice Burns reflection of NFT on bridge
	/// @param collectionAddr A
	/// @param tokenIds Array of tokenIds to bridge to target chain
	/// @param targetNetworkId target network ID from LayerZero's ecosystem (different from chain ID)
	/// @param _refundAddress Address to return excessive native tokens
	/// @param _zroPaymentAddress Currently takes zero address, but left as parameter according to LayerZero`s guidelines
	/// @param _adapterParams abi.encode(1, gasLimit) gasLimit for transaction on target chain
	/// @dev _adapterParams`s gasLimit should be 2,200,000 for bridge of single token to a new chain (chain where is no ReflectedNFT contract)
	/// @dev _adapterParams`s gasLimit should be 300,000 for bridge of signle token to already deployed ReflectedNFT contract
	/// @dev Original NFT collection is passed in message of bridge from any to any chain
	/// @dev Original NFT collection address is used as a unique identifier at all chains
	/// @dev In message provides name and symbols of bridged NFT collection to deploy exact same NFT contract on target chain
	/// @dev In message provides tokenIds and tokenURIs of bridged NFT to mint exact same NFTs on target chain
	function createReflection(
		address collectionAddr,
		uint256[] memory tokenIds,
		uint16 targetNetworkId,
		address payable _refundAddress,
		address _zroPaymentAddress,
		bytes memory _adapterParams
	) public payable {
		require(isEligibleCollection[collectionAddr], 'Mirror: collection is not eligible');
		require(tokenIds.length > 0, "Mirror: tokenIds weren't provided");
		require(tokenIds.length <= reflectionAmountLimit, "Mirror: can't reflect more than limit");

		_deductFee();

		ReflectedNFT collection = ReflectedNFT(collectionAddr);

		string memory name = collection.name();
		string memory symbol = collection.symbol();

		string[] memory tokenURIs = new string[](tokenIds.length);

		for (uint256 i = 0; i < tokenIds.length; i++) {
			string memory tokenURI = collection.tokenURI(tokenIds[i]);
			tokenURIs[i] = tokenURI;
		}

		address originalCollectionAddress;

		if (isReflection[collectionAddr]) {
			//	NFT is reflection - burn

			for (uint256 i = 0; i < tokenIds.length; i++) {
				collection.burn(msg.sender, tokenIds[i]);
			}

			originalCollectionAddress = originalCollectionAddresses[collectionAddr];
		} else {
			// Is original NFT - lock NFT

			for (uint256 i = 0; i < tokenIds.length; i++) {
				collection.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
			}

			isOriginalChainForCollection[collectionAddr] = true;
			originalCollectionAddress = collectionAddr;
		}

		bytes memory _payload = abi.encode(originalCollectionAddress, name, symbol, tokenIds, tokenURIs, msg.sender);

		_lzSend(targetNetworkId, _payload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value - feeAmount);

		emit BridgeNFT(originalCollectionAddress, name, symbol, tokenIds, tokenURIs, msg.sender);
	}

	/// @dev Function inherited from NonBlockingLzApp
	/// @dev Called by lzReceive() that is triggered by LzEndpoint
	/// @dev Calles _reflect() to finish bridge process
	function _nonblockingLzReceive(uint16, bytes memory, uint64, bytes memory payload) internal virtual override {
		(
			address originalCollectionAddr,
			string memory name,
			string memory symbol,
			uint256[] memory tokenIds,
			string[] memory tokenURIs,
			address _owner
		) = abi.decode(payload, (address, string, string, uint256[], string[], address));

		_reflect(originalCollectionAddr, name, symbol, tokenIds, tokenURIs, _owner);
	}

	/// @notice Function finishing bridge process
	/// @notice Deploys ReflectedNFT contract if collection was bridged to current chain for the first time
	/// @notice Uses existing ReflectedNFT contract if collection was bridged to that chain before
	/// @notice Mints NFT-reflection on ReflectedNFT contract
	/// @notice Returns (unlocks) NFT to owner if current chain is original for bridged NFT
	/// @param originalCollectionAddr Address of original collection on original chain as a unique identifier
	/// @param name name of original collection to mint ReflectedNFT if needed
	/// @param symbol symbol of original collection to mint ReflectedNFT if needed
	/// @param tokenIds Array of tokenIds of bridged NFTs to mint exact same tokens or to unlocks it
	/// @param tokenURIs Array of tokenURIs of bridged NFTs to mint exact same tokens if needed
	/// @param _owner Address to mint or return token to
	function _reflect(
		address originalCollectionAddr,
		string memory name,
		string memory symbol,
		uint256[] memory tokenIds,
		string[] memory tokenURIs,
		address _owner
	) internal {
		bool isOriginalChain = isOriginalChainForCollection[originalCollectionAddr];

		if (isOriginalChain) {
			// Unlock NFT and return to owner

			for (uint256 i = 0; i < tokenIds.length; i++) {
				ReflectedNFT(originalCollectionAddr).safeTransferFrom(address(this), _owner, tokenIds[i]);
			}

			emit NFTReturned(originalCollectionAddr, tokenIds, _owner);
		} else {
			bool isThereReflectionContract = reflection[originalCollectionAddr] != address(0);

			// Get ReflectedNFT address from storage (if exists) or deploy
			address collectionAddr;

			if (isThereReflectionContract) {
				collectionAddr = reflection[originalCollectionAddr];
			} else {
				collectionAddr = _deployReflection(originalCollectionAddr, name, symbol);
			}

			// Make eligible to be able to bridge
			isEligibleCollection[collectionAddr] = true;

			// Mint NFT-reflections
			for (uint256 i = 0; i < tokenIds.length; i++) {
				ReflectedNFT(collectionAddr).mint(_owner, tokenIds[i], tokenURIs[i]);
			}

			emit NFTBridged(originalCollectionAddr, tokenIds, tokenURIs, _owner);
		}
	}

	/// @notice Updated collection eligibility to given parameter
	/// @param collection collection address
	/// @param eligibility boolean for eligibilty
	/// @dev only owner can call
	function changeCollectionEligibility(address collection, bool eligibility) external onlyOwner {
		isEligibleCollection[collection] = eligibility;
	}

	/// @notice Changes limit for bridging batch of tokens
	/// @param newReflectionAmountLimit Amount of tokens that can be bridged in single transaction
	/// @dev only owner can call
	function changeReflectionAmountLimit(uint256 newReflectionAmountLimit) external onlyOwner {
		reflectionAmountLimit = newReflectionAmountLimit;
	}

	/**
	 * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
	 * by `operator` from `from`, this function is called.
	 *
	 * It must return its Solidity selector to confirm the token transfer.
	 * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
	 *
	 * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
	 */
	function onERC721Received(
		address operator,
		address from,
		uint256 tokenId,
		bytes calldata data
	) external returns (bytes4) {
		emit NFTReceived(operator, from, tokenId, data);
		return IERC721Receiver.onERC721Received.selector;
	}

	/// @dev Called in createReflection() to make array from signle element
	/// @dev Using [element] drops "Invalid implicit conversion from uint256[1] memory to uint256[]"
	function _toSingletonArray(uint element) internal pure returns (uint[] memory) {
		uint[] memory array = new uint[](1);
		array[0] = element;
		return array;
	}
}