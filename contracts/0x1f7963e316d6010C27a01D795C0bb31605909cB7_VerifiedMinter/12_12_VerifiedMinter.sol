//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {SSTORE2} from "./SSTORE2/SSTORE2.sol";

import {IVerified} from "./IVerified.sol";
import {IDataHolder} from "./IDataHolder.sol";

/// @title VerifiedMinter
/// @author @dievardump
contract VerifiedMinter is Ownable {
	error InvalidValue();
	error InvalidSignature();
	error UnknownOwner();
	error InvalidVerifiedID();
	error TransferFundsError();

	address public immutable VERIFIED_NFTS;
	address public immutable VERIFIED_DATA_HOLDER;

	address public immutable FEE_RECIPIENT;

	uint256 public mintFee = 0.0048 ether;
	uint256 public addFormatFee = 0.0024 ether;

	address public signer;
	address public ownershipChecker;

	constructor(
		address nfts,
		address dataHolder,
		address newSigner,
		address newFeeRecipient
	) {
		VERIFIED_NFTS = nfts;
		VERIFIED_DATA_HOLDER = dataHolder;

		FEE_RECIPIENT = newFeeRecipient;

		signer = newSigner;
	}

	// =============================================================
	//                   				Getters
	// =============================================================

	/// @notice function that tries to hget an NFT owner address... might need to deploy a specific contract
	///         for this if there is a need for collections not implemneting ownerOf rightly
	/// @param collection the collection
	/// @param tokenId the token id
	function tryOwner(address collection, uint256 tokenId) public view returns (address to) {
		// if the contract is an ERC721 (or the CryptoKitty, not sure they support IERC721 or the Meta interface), check owner
		if (
			collection == 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d ||
			IERC721(collection).supportsInterface(type(IERC721).interfaceId)
		) {
			to = IERC721(collection).ownerOf(tokenId);
		} else if (collection == 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB) {
			// else punks maybe?
			to = IOwnershipChecker(collection).punkIndexToAddress(tokenId);
		} else {
			address checker = ownershipChecker;

			// or maybe I added a contract to add custom ownership checks?
			if (checker != address(0)) {
				try IOwnershipChecker(checker).ownerOf(collection, tokenId) returns (address owner_) {
					to = owner_;
				} catch (bytes memory) {}
			} else {
				// try again with a simple ownerOf(), might probably work with 99% of contracts not using the right supportsInterface
				to = IERC721(collection).ownerOf(tokenId);
			}
		}
	}

	/// @notice verifies that the data have been signed by the backend
	/// @param collection the collection token
	/// @param tokenId the token id
	/// @param format the format for those data
	/// @param colors the colors for the output
	/// @param grid the grid (index in colors data)
	/// @param proof the backend signature
	function verify(
		address collection,
		uint256 tokenId,
		uint256 format,
		bytes calldata colors,
		bytes calldata grid,
		bytes calldata proof
	) public view returns (bytes memory) {
		// build the data, this is what will be saved on-chain
		bytes memory data = abi.encode(collection, tokenId, format, colors, grid);

		// verifies the data signature
		if (signer != ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(data)), proof)) {
			revert InvalidSignature();
		}

		return data;
	}

	// =============================================================
	//                   				Interactions
	// =============================================================

	/// @notice allows to add another format to your verified id
	/// @param verifiedId the verified id to add a format to
	/// @param collection the collection token
	/// @param tokenId the token id
	/// @param format the format for those data
	/// @param colors the colors for the output
	/// @param grid the grid (index in colors data)
	/// @param proof the backend signature
	/// @param selectFormat if the format should be selected on the token
	function addFormat(
		uint256 verifiedId,
		address collection,
		uint256 tokenId,
		uint256 format,
		bytes calldata colors,
		bytes calldata grid,
		bytes calldata proof,
		bool selectFormat
	) external payable {
		// verifies sent value == the expected fee
		if (msg.value != addFormatFee) {
			revert InvalidValue();
		}

		bytes memory data = verify(collection, tokenId, format, colors, grid, proof);

		if (msg.value > 0) {
			(bool success, ) = FEE_RECIPIENT.call{value: msg.value}("");
			if (!success) {
				revert TransferFundsError();
			}
		}

		// we make sure dataHolder(collection, tokenId).verifiedId == verifiedId
		if (
			verifiedId == 0 ||
			verifiedId != IDataHolder(VERIFIED_DATA_HOLDER).getOriginTokenVerifiedId(collection, tokenId)
		) {
			revert InvalidVerifiedID();
		}

		// we save the data into a contract
		address dataHolder = SSTORE2.write(data);

		// we save the new format
		IDataHolder(VERIFIED_DATA_HOLDER).safeSetData(collection, tokenId, format, dataHolder);

		// and if we want to change format, let's change
		if (selectFormat) {
			IVerified(VERIFIED_NFTS).setExtraData(verifiedId, uint24(format));
		}
	}

	/// @notice allows to mint a new token with the given data
	/// @param collection the collection token
	/// @param tokenId the token id
	/// @param format the format for those data
	/// @param colors the colors for the output
	/// @param grid the grid (index in colors data)
	/// @param proof the backend signature
	function mint(
		address collection,
		uint256 tokenId,
		uint256 format,
		bytes calldata colors,
		bytes calldata grid,
		bytes calldata proof
	) external payable {
		if (msg.value != mintFee) {
			revert InvalidValue();
		}

		bytes memory data = verify(collection, tokenId, format, colors, grid, proof);

		_mint(collection, tokenId, format, data);

		if (msg.value > 0) {
			(bool success, ) = FEE_RECIPIENT.call{value: msg.value}("");
			if (!success) {
				revert TransferFundsError();
			}
		}
	}

	// =============================================================
	//                   				Gated Owner
	// =============================================================

	/// @notice allows owner to set the signer
	/// @param newSigner the new signer
	function setSigner(address newSigner) external onlyOwner {
		signer = newSigner;
	}

	/// @notice allows owner to set the ownership checker contract
	/// @param newOwnershipChecker the new checker
	function setOwnershipChecker(address newOwnershipChecker) external onlyOwner {
		ownershipChecker = newOwnershipChecker;
	}

	/// @notice allows owner to update the mint fee
	/// @param newMintFee the new mint fee
	function setMintFee(uint256 newMintFee) external onlyOwner {
		mintFee = newMintFee;
	}

	/// @notice allows owner to update the add format fee
	/// @param newAddFormatFee the new add format fee
	function setAddFormatFee(uint256 newAddFormatFee) external onlyOwner {
		addFormatFee = newAddFormatFee;
	}

	// =============================================================
	//                   				Internals
	// =============================================================

	function _mint(
		address collection,
		uint256 tokenId,
		uint256 format,
		bytes memory data
	) internal {
		address to = tryOwner(collection, tokenId);
		if (to == address(0)) {
			revert UnknownOwner();
		}

		// we mint the verified token to the current owner of the original token
		uint256 verifiedId = IVerified(VERIFIED_NFTS).mint(to, uint24(format));

		// we save the data into a contract
		address dataHolder = SSTORE2.write(data);

		// we link tokenId and
		IDataHolder(VERIFIED_DATA_HOLDER).initVerifiedTokenData(verifiedId, collection, tokenId, format, dataHolder);
	}
}

interface IOwnershipChecker {
	function punkIndexToAddress(uint256) external view returns (address);

	function ownerOf(address, uint256) external view returns (address);
}