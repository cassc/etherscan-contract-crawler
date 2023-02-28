// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./library/operator_filterer/DefaultOperatorFilterer.sol";

error ArtDubai__TokenNotForSale();
error ArtDubai__WrongEtherAmmount();
error ArtDubai__ExceedingMaxSupply();
error ArtDubai__ExceedingTokensPerWalletLimit();

error ArtDubai__ExceedingSignatureMaxQuantity();
error ArtDubai__HashComparisonFailed();
error ArtDubai__SignatureExpired();
error ArtDubai__UntrustedSigner();
error ArtDubai__SignatureAlreadyUsed();

error ArtDubai__InvalidInput();
error ArtDubai__NothingToWithdraw();

/**
 * @dev A struct, that contains the sale conditions for a token.
 *
 * @param supplyLimit The maximum amount of tokens that can be minted.
 * @param maxTokensPerWallet The maximum amount of tokens that can be minted per wallet.
 * @param weiTokenPrice The price of a token in wei.
 */
struct SaleConditions {
	uint16 supplyLimit;
	uint16 maxTokensPerWallet;
	uint256 weiTokenPrice;
}

/**
 * @dev A signature package, that secures the minting of tokens.
 *
 * @param hash The hash of the minting operation.
 * @param signature The signature for the hash.
 * @param signatureValidUntil The timestamp until which the signature is valid.
 * @param nonce The nonce, that is used to prevent replay attacks.
 * @param maxQuantity The maximum quantity of tokens that can be minted with this signature.
 */
struct SignaturePackage {
	bytes32 hash;
	bytes signature;
	uint32 signatureValidUntil;
	uint64 nonce;
	uint16 maxQuantity;
}

/**
 * @title Art Dubai
 * @author DeployLabs.io
 *
 * @dev This contract is used as a base contract for all Art Dubai collections.
 */
abstract contract ArtDubai is ERC1155, ERC1155Supply, Ownable, DefaultOperatorFilterer {
	bytes8 internal immutable i_hashSalt;
	address internal immutable i_signerAddress;

	mapping(uint64 => bool) internal s_usedNonces;

	mapping(uint8 => SaleConditions) internal s_saleConditions;
	mapping(uint8 => mapping(address => uint16)) internal s_numberMinted;

	string internal s_baseTokenUri;

	constructor(bytes8 hashSalt, address signerAddress) ERC1155("") {
		i_hashSalt = hashSalt;
		i_signerAddress = signerAddress;
	}

	/**
	 * @dev Mint a token to a specified wallet.
	 *
	 * @param signaturePackage The signature package for security.
	 * @param mintTo The address to mint the token to.
	 * @param tokenId The id of the token to mint.
	 * @param quantity The quantity of tokens to mint.
	 */
	function mint(
		SignaturePackage calldata signaturePackage,
		address mintTo,
		uint8 tokenId,
		uint16 quantity
	) external payable {
		SaleConditions memory conditions = s_saleConditions[tokenId];

		if (!isTokenForSale(tokenId)) revert ArtDubai__TokenNotForSale();

		if (msg.value != conditions.weiTokenPrice * quantity) revert ArtDubai__WrongEtherAmmount();
		if (totalSupply(tokenId) + quantity > conditions.supplyLimit)
			revert ArtDubai__ExceedingMaxSupply();
		if (s_numberMinted[tokenId][mintTo] + quantity > conditions.maxTokensPerWallet)
			revert ArtDubai__ExceedingTokensPerWalletLimit();

		if (quantity > signaturePackage.maxQuantity) revert ArtDubai__ExceedingSignatureMaxQuantity();
		if (signaturePackage.signatureValidUntil < block.timestamp) revert ArtDubai__SignatureExpired();
		if (!_isCorrectMintOperationHash(signaturePackage, tokenId, mintTo))
			revert ArtDubai__HashComparisonFailed();
		if (!_isTrustedSigner(signaturePackage.hash, signaturePackage.signature))
			revert ArtDubai__UntrustedSigner();
		if (s_usedNonces[signaturePackage.nonce]) revert ArtDubai__SignatureAlreadyUsed();

		s_numberMinted[tokenId][mintTo] += quantity;
		s_usedNonces[signaturePackage.nonce] = true;

		_mint(mintTo, tokenId, quantity, "");
	}

	/**
	 * @dev Withdraw the balance of the contract.
	 *
	 * @param to The address to send the balance to.
	 */
	function withdraw(address payable to) external onlyOwner {
		uint256 balance = address(this).balance;
		if (balance == 0) revert ArtDubai__NothingToWithdraw();
		if (to == address(0)) revert ArtDubai__InvalidInput();

		to.transfer(balance);
	}

	/**
	 * @dev Set base URI for token metadata.
	 *
	 * @param baseUri The base URI for token metadata.
	 */
	function setBaseUri(string calldata baseUri) external onlyOwner {
		s_baseTokenUri = baseUri;
	}

	/**
	 * @dev Sets sale conditions for a set of tokens.
	 *
	 * @param tokenIds Token IDs
	 * @param saleConditions Sale conditions for each token
	 */
	function setSaleConditions(
		uint8[] calldata tokenIds,
		SaleConditions[] calldata saleConditions
	) external onlyOwner {
		if (tokenIds.length != saleConditions.length) revert ArtDubai__InvalidInput();

		for (uint8 i = 0; i < tokenIds.length; i++) {
			s_saleConditions[tokenIds[i]] = saleConditions[i];
		}
	}

	/**
	 * @dev Gets sale conditions for a token.
	 *
	 * @param tokenId Token ID
	 *
	 * @return conditions Sale conditions.
	 */
	function getSaleConditions(
		uint8 tokenId
	) external view returns (SaleConditions memory conditions) {
		conditions = s_saleConditions[tokenId];
	}

	/**
	 * @dev Get the number of tokens minted by a wallet.
	 *
	 * @param tokenId The id of the token.
	 * @param wallet The wallet to check.
	 *
	 * @return countMinted The number of tokens minted by the wallet.
	 */
	function getMintedCount(
		uint8 tokenId,
		address wallet
	) external view returns (uint16 countMinted) {
		countMinted = s_numberMinted[tokenId][wallet];
	}

	// Overrides for marketplace restrictions.
	function setApprovalForAll(
		address operator,
		bool approved
	) public override onlyAllowedOperatorApproval(operator) {
		super.setApprovalForAll(operator, approved);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		uint256 amount,
		bytes memory data
	) public override onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId, amount, data);
	}

	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual override onlyAllowedOperator(from) {
		super.safeBatchTransferFrom(from, to, ids, amounts, data);
	}

	/**
	 * @dev Check, if a token is for sale.
	 *
	 * @param tokenId The id of the token.
	 *
	 * @return isForSale Whether the token is for sale.
	 */
	function isTokenForSale(uint8 tokenId) public view virtual returns (bool isForSale) {
		isForSale = s_saleConditions[tokenId].supplyLimit > 0;
	}

	/**
	 * @dev Get data used to generate the signature.
	 *
	 * @return hashSalt The hash salt.
	 * @return signerAddress The signer address.
	 */
	function getSignatureData() public view returns (bytes8 hashSalt, address signerAddress) {
		hashSalt = i_hashSalt;
		signerAddress = i_signerAddress;
	}

	/**
	 * @dev Get the URI for a token.
	 *
	 * @param tokenId The token ID.
	 *
	 * @return uri The URI for the token.
	 */
	function uri(uint256 tokenId) public view virtual override returns (string memory) {
		return string(abi.encodePacked(s_baseTokenUri, Strings.toString(tokenId)));
	}

	// Override for ERC1155Supply.
	function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal override(ERC1155, ERC1155Supply) {
		super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
	}

	/**
	 * @dev Check whether a message hash is the one that has been signed.
	 *
	 * @param signaturePackage The signature package.
	 * @param tokenId The id of the token.
	 * @param mintTo The address to mint to.
	 *
	 * @return isCorrectMintOperationHash Whether the message hash matches the one that has been signed.
	 */
	function _isCorrectMintOperationHash(
		SignaturePackage calldata signaturePackage,
		uint8 tokenId,
		address mintTo
	) internal view returns (bool isCorrectMintOperationHash) {
		bytes memory message = abi.encodePacked(
			i_hashSalt,
			mintTo,
			uint64(block.chainid),
			tokenId,
			signaturePackage.maxQuantity,
			signaturePackage.signatureValidUntil,
			signaturePackage.nonce
		);
		bytes32 messageHash = keccak256(message);

		isCorrectMintOperationHash = messageHash == signaturePackage.hash;
	}

	/**
	 * @dev Check whether a message was signed by a trusted address.
	 *
	 * @param hash The hash of the message.
	 * @param signature The signature of the message.
	 *
	 * @return isTrustedSigner Whether the message was signed by a trusted address.
	 */
	function _isTrustedSigner(
		bytes32 hash,
		bytes memory signature
	) internal view returns (bool isTrustedSigner) {
		isTrustedSigner = i_signerAddress == ECDSA.recover(hash, signature);
	}
}