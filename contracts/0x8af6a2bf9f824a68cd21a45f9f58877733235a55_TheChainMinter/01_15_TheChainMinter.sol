//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ITheChainCollection} from "./interfaces/ITheChainCollection.sol";
import {ITheChainMinter} from "./interfaces/ITheChainMinter.sol";
import {ITheChainSales} from "./interfaces/ITheChainSales.sol";

contract TheChainMinter is ITheChainMinter, Ownable, EIP712 {
	error InvalidSignature();

	bytes32 public constant MINT =
		keccak256(
			bytes(
				"Mint(address minter,uint256 tokenId,address creator,bytes32 currentHash,bytes32 previousHash,string uri)"
			)
		);

	string public constant THE_CHAIN_VERSION = "1";

	address public immutable THE_CHAIN;

	address public immutable SELLER;

	/// @notice accounts allowed to sign sales data
	mapping(address => bool) public signers;

	constructor(
		address initChain,
		address initSeller,
		// address initEscrow,
		address[] memory initSigners
	) EIP712("THE_CHAIN", THE_CHAIN_VERSION) {
		THE_CHAIN = initChain;

		SELLER = initSeller;

		// escrow = initEscrow;

		for (uint256 i; i < initSigners.length; i++) {
			signers[initSigners[i]] = true;
		}
	}

	/// @notice returns the domain separator for this contract
	/// @return the domain separator
	function domainSeparator() public view returns (bytes32) {
		return _domainSeparatorV4();
	}

	// =============================================================
	//                       	   Interactions
	// =============================================================

	/// @notice allows to mint
	/// @param tokenId the token id to mint
	/// @param creator the creator address
	/// @param currentHash the "The Chain" block hash
	/// @param previousHash the hash of the previous "the Chain" block
	/// @param price the price to sell it at
	/// @param startsSaleAt the timestamp (in seconds) when the sale for this artwork can start
	/// @param uri the artwork URI
	/// @param proof the signer signature, prooving this artwork & its metadata belong in this collection
	function mint(
		uint256 tokenId,
		address creator,
		bytes32 currentHash,
		bytes32 previousHash,
		uint96 price,
		uint32 startsSaleAt,
		string calldata uri,
		bytes calldata proof
	) external {
		// verify (tokenId, creator, hash, previousHash, uri) has been signed by a signer
		_verifyMint(tokenId, creator, currentHash, previousHash, uri, proof);

		// mint & transfer to sale contract
		ITheChainCollection(THE_CHAIN).mint(tokenId, creator, SELLER, currentHash, previousHash, uri);

		// Put on sale
		ITheChainSales(SELLER).createOrder(creator, price, uint32(tokenId), startsSaleAt);
	}

	// =============================================================
	//                       	 Gated Operators
	// =============================================================

	// =============================================================
	//                       	 Gated Owner
	// =============================================================

	/// @notice Allows owner to add signers to this contract
	/// @param signersList the new signers to add/remove
	/// @param isActive if the signers should be added or removed
	function setSigners(address[] memory signersList, bool isActive) public onlyOwner {
		for (uint256 i; i < signersList.length; i++) {
			signers[signersList[i]] = isActive;
		}
	}

	// =============================================================
	//                       	 Internals
	// =============================================================

	/// @dev verifies the data have been signed by one of the_chain admin
	function _verifyMint(
		uint256 tokenId,
		address creator,
		bytes32 currentHash,
		bytes32 previousHash,
		string memory uri,
		bytes calldata proof
	) internal view {
		bytes32 digest = ECDSA.toTypedDataHash(
			domainSeparator(),
			keccak256(
				abi.encode(MINT, address(this), tokenId, creator, currentHash, previousHash, keccak256(bytes(uri)))
			)
		);

		address signer = ECDSA.recover(digest, proof);
		if (!signers[signer]) {
			revert InvalidSignature();
		}
	}
}