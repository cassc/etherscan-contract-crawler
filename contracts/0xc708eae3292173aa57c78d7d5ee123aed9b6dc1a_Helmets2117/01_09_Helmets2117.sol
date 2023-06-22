// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
    ________  ____  ____ _________       ___ ___          .__                     __           
    \_____  \/_   |/_   |\______  \     /   |   \   ____  |  |    _____    ____ _/  |_  ______ 
     /  ____/ |   | |   |    /    /    /    ~    \_/ __ \ |  |   /     \ _/ __ \\   __\/  ___/ 
    /       \ |   | |   |   /    /     \    Y    /\  ___/ |  |__|  Y Y  \\  ___/ |  |  \___ \  
    \_______ \|___| |___|  /____/       \___|_  /  \___  >|____/|__|_|  / \___  >|__| /____  > 
            \/                                \/       \/             \/      \/           \/  

    2117 Helmets All Rights Reserved 2022
    noticeeloped by DeployLabs.io ([email protected])
*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title 2117 Helmets
 * @author DeployLabs.io
 *
 * @notice Helmets is a contract for managing claims of 2117 Helmets NFTs.
 */
contract Helmets2117 is ERC721A("2117 Helmets", "HELM"), Ownable {
	/**
	 * @notice A signature package, that secures the claiming and customization of tokens.
	 *
	 * @param hash The hash of the claiming operation.
	 * @param signature The signature for the hash.
	 * @param signatureValidUntil The timestamp until which the signature is valid.
	 * @param nonce The nonce, that is used to prevent replay attacks.
	 */
	struct SignaturePackage {
		bytes32 hash;
		bytes signature;
		uint32 validUntil;
		uint32 nonce;
	}

	address private constant SIGNER_ADDRESS = 0x254E79799F35077072B60AD2e47fb5c499D5e95a;

	string private s_defaultHelmHash = "QmSyFqWzpcF9gmsZVnQyN12DRAsybT1FZymrvZHfHn971t";

	mapping(uint16 => string) private s_helmetHashes;
	mapping(uint16 => bool) private s_citizenshipUsed;
	mapping(uint32 => bool) private s_usedNonces;

	event CitizenshipsUsed(uint16[] indexed tokenIds);
	event HelmetCustomized(uint16 indexed tokenId, string helmetHash);

	error Helmets2117__EmptyCitizenshipsArray();
	error Helmets2117__CitizenshipAlreadyUsed();

	error Helmets2117__SignatureExpired();
	error Helmets2117__HashComparisonFailed();
	error Helmets2117__UntrustedSigner();
	error Helmets2117__SignatureAlreadyUsed();

	error Helmets2117__HelmetAlreadyCustomized();
	error Helmets2117__InvalidHelmHash();

	error Helmets2117__TokenDoesNotExist();

	/**
	 * @notice Claim a token, using citizenship tokens, owned by the caller.
	 *
	 * @param signaturePackage The signature package.
	 * @param citizenshipIds The citizenship IDs.
	 */
	function claimHelmets(
		SignaturePackage calldata signaturePackage,
		uint16[] calldata citizenshipIds
	) external {
		if (citizenshipIds.length == 0) revert Helmets2117__EmptyCitizenshipsArray();

		for (uint16 i = 0; i < citizenshipIds.length; i++) {
			uint16 citizenshipId = citizenshipIds[i];
			if (isCitizenshipUsed(citizenshipId)) revert Helmets2117__CitizenshipAlreadyUsed();

			s_citizenshipUsed[citizenshipId] = true;
		}

		if (signaturePackage.validUntil < block.timestamp) revert Helmets2117__SignatureExpired();
		if (!_isCorrectClaimOperationHash(signaturePackage, citizenshipIds, msg.sender))
			revert Helmets2117__HashComparisonFailed();
		if (!_isTrustedSigner(signaturePackage.hash, signaturePackage.signature))
			revert Helmets2117__UntrustedSigner();
		if (s_usedNonces[signaturePackage.nonce]) revert Helmets2117__SignatureAlreadyUsed();

		s_usedNonces[signaturePackage.nonce] = true;
		emit CitizenshipsUsed(citizenshipIds);

		_safeMint(msg.sender, citizenshipIds.length);
	}

	/**
	 * @notice Apply a customization to a token.
	 *
	 * @param signaturePackage The signature package.
	 * @param tokenId The token ID.
	 * @param helmetHash The hash of the helmet metadata.
	 */
	function applyHelmetCustomization(
		SignaturePackage calldata signaturePackage,
		uint16 tokenId,
		string memory helmetHash
	) external payable {
		if (isHelmetCustomized(tokenId)) revert Helmets2117__HelmetAlreadyCustomized();
		if (bytes(helmetHash).length == 0) revert Helmets2117__InvalidHelmHash();

		if (signaturePackage.validUntil < block.timestamp) revert Helmets2117__SignatureExpired();
		if (!_isCorrectCustomizeOperationHash(signaturePackage, tokenId, helmetHash, msg.value))
			revert Helmets2117__HashComparisonFailed();
		if (!_isTrustedSigner(signaturePackage.hash, signaturePackage.signature))
			revert Helmets2117__UntrustedSigner();
		if (s_usedNonces[signaturePackage.nonce]) revert Helmets2117__SignatureAlreadyUsed();

		s_usedNonces[signaturePackage.nonce] = true;
		emit HelmetCustomized(tokenId, helmetHash);

		s_helmetHashes[tokenId] = helmetHash;
	}

	/**
	 * @dev Set the default hash of the helmet metadata.
	 *
	 * @param newDefaultHelmHash The new default hash of the helmet metadata.
	 */
	function setDefaultHelmHash(string memory newDefaultHelmHash) external onlyOwner {
		s_defaultHelmHash = newDefaultHelmHash;
	}

	/**
	 * @dev Withdraw all money from the contract.
	 *
	 * @param to The address to withdraw the money to.
	 */
	function withdraw(address payable to) external onlyOwner {
		payable(to).transfer(address(this).balance);
	}

	/**
	 * @notice Get the metadata URI of a token.
	 *
	 * @param tokenId The token ID.
	 *
	 * @return The metadata URI.
	 */
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		if (!_exists(tokenId)) revert Helmets2117__TokenDoesNotExist();

		string memory helmetHash = isHelmetCustomized(uint16(tokenId))
			? s_helmetHashes[uint16(tokenId)]
			: s_defaultHelmHash;
		return string(abi.encodePacked("ipfs://", helmetHash));
	}

	/**
	 * @notice Check whether a citizenship ID has been used to claim a token.
	 *
	 * @param citizenshipId The citizenship ID.
	 *
	 * @return Whether the citizenship ID has been used.
	 */
	function isCitizenshipUsed(uint16 citizenshipId) public view returns (bool) {
		return s_citizenshipUsed[citizenshipId];
	}

	/**
	 * @notice Check whether a token has been customized.
	 *
	 * @param tokenId The token ID.
	 *
	 * @return Whether the token has been customized.
	 */
	function isHelmetCustomized(uint16 tokenId) public view returns (bool) {
		return bytes(s_helmetHashes[tokenId]).length > 0;
	}

	/**
	 * @dev Check whether a message hash is the one that has been signed for the claiming operation.
	 *
	 * @param signaturePackage The signature package.
	 * @param citizenshipIds The citizenship IDs.
	 * @param mintTo The address to mint to.
	 *
	 * @return Whether the message hash matches the one that has been signed.
	 */
	function _isCorrectClaimOperationHash(
		SignaturePackage calldata signaturePackage,
		uint16[] calldata citizenshipIds,
		address mintTo
	) internal view returns (bool) {
		bytes memory citizenshipIdsBytes;

		for (uint16 i = 0; i < citizenshipIds.length; i++) {
			citizenshipIdsBytes = abi.encodePacked(citizenshipIdsBytes, citizenshipIds[i]);
		}

		bytes memory message = abi.encodePacked(
			uint32(block.chainid),
			signaturePackage.nonce,
			signaturePackage.validUntil,
			mintTo,
			citizenshipIdsBytes
		);
		bytes32 messageHash = keccak256(message);

		return messageHash == signaturePackage.hash;
	}

	/**
	 * @dev Check whether a message hash is the one that has been signed for the customization operation.
	 *
	 * @param signaturePackage The signature package.
	 * @param tokenId The token ID.
	 * @param helmetHash The hash of the helmet metadata.
	 * @param weiCustomizationPrice The value, paid for the customization.
	 *
	 * @return Whether the message hash matches the one that has been signed.
	 */
	function _isCorrectCustomizeOperationHash(
		SignaturePackage calldata signaturePackage,
		uint16 tokenId,
		string memory helmetHash,
		uint256 weiCustomizationPrice
	) internal view returns (bool) {
		bytes memory message = abi.encodePacked(
			uint32(block.chainid),
			signaturePackage.nonce,
			signaturePackage.validUntil,
			tokenId,
			helmetHash,
			weiCustomizationPrice
		);
		bytes32 messageHash = keccak256(message);

		return messageHash == signaturePackage.hash;
	}

	/**
	 * @dev Check whether a message was signed by a trusted address.
	 *
	 * @param hash The hash of the message.
	 * @param signature The signature of the message.
	 *
	 * @return Whether the message was signed by a trusted address.
	 */
	function _isTrustedSigner(bytes32 hash, bytes memory signature) internal pure returns (bool) {
		return SIGNER_ADDRESS == ECDSA.recover(hash, signature);
	}
}