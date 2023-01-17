// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/*
	      ::::::::  :::    :::   :::   :::    :::::::: 
	    :+:    :+: :+:    :+:  :+:+: :+:+:  :+:    :+: 
	   +:+        +:+    +:+ +:+ +:+:+ +:+ +:+         
	  +#++:++#++ +#++:++#++ +#+  +:+  +#+ :#:          
	        +#+ +#+    +#+ +#+       +#+ +#+   +#+#    
	#+#    #+# #+#    #+# #+#       #+# #+#    #+#     
	########  ###    ### ###       ###  ########       

    Sneaker Heads x Mag Park All Rights Reserved 2023
    Developed by DeployLabs.io ([email protected])
*/

import "./library/erc721A/ERC721A.sol";

import "./library/Manageable.sol";
import "./library/operator_filterer/DefaultOperatorFilterer.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error SneakerHeadsxMagPark__SalesAreClosed();
error SneakerHeadsxMagPark__SalesHaveEnded();
error SneakerHeadsxMagPark__ExceedingMintingLimits();
error SneakerHeadsxMagPark__WrongEthAmount();

error SneakerHeadsxMagPark__HashComparisonFailed();
error SneakerHeadsxMagPark__UntrustedSigner();
error SneakerHeadsxMagPark__SignatureAlreadyUsed();

error SneakerHeadsxMagPark__TeamTokensAlreadyReserved();
error SneakerHeadsxMagPark__NothingToWithdraw();

/**
 * @title SneakerHeadsxMagPark
 * @author DeployLabs.io
 *
 * @dev This contract is used for SneakerHeadsxMagPark NFT collection
 */
contract SneakerHeadsxMagPark is ERC721A, Manageable, DefaultOperatorFilterer, ReentrancyGuard {
	enum SALE_STAGE {
		CLOSED,
		VIP,
		ALLOWLIST,
		PUBLIC,
		ENDED
	}

	bytes8 private constant HASH_SALT = 0xa4dae93d75b4175c;
	address private constant SIGNER_ADDRESS = 0xFc8931C9bD3bf8F8D4Ae10215168e4062F25Aa57;

	uint16 private constant TEAM_TOKENS_COUNT = 11;

	uint32 private constant VIP_SALE_START_TIME = 1674032400;
	uint32 private constant ALLOWLIST_SALE_START_TIME = 1674118800;
	uint32 private constant PUBLIC_SALE_START_TIME = 1674205200;
	uint32 private constant SALES_END_TIME = 1674216000;

	uint256 private constant VIP_SALE_PRICE = 0.099 ether;
	uint256 private constant ALLOWLIST_SALE_PRICE = 0.12 ether;
	uint256 private constant PUBLIC_SALE_PRICE = 0.15 ether;

	string private s_baseTokenURI;

	mapping(SALE_STAGE => mapping(address => uint256)) private s_numberMintedDuringSaleStage;

	mapping(uint64 => bool) private s_usedNonces;

	bool private s_teamTokensReserved = false;

	constructor() ERC721A("Sneaker Heads x Mag Park", "SHMG") {}

	/**
	 * @dev This function is used for receiving any amount of ether
	 */
	receive() external payable {}

	/**
	 * @dev This function is used for minting tokens to the caller
	 *
	 * @param hash Hash from backend for signature verification
	 * @param signature Signature from backend for signature verification
	 * @param nonce Nonce from backend for signature verification
	 * @param maxQuantity Maximum quantity of tokens that can be minted by the caller
	 * @param quantity Quantity of tokens to mint
	 */
	function mint(
		bytes32 hash,
		bytes memory signature,
		uint64 nonce,
		uint64 maxQuantity,
		uint256 quantity
	) external payable nonReentrant {
		SALE_STAGE saleStage = getCurrentSaleStage();
		if (saleStage == SALE_STAGE.CLOSED) revert SneakerHeadsxMagPark__SalesAreClosed();
		if (saleStage == SALE_STAGE.ENDED) revert SneakerHeadsxMagPark__SalesHaveEnded();

		if (numberMinted(saleStage, msg.sender) + quantity > maxQuantity)
			revert SneakerHeadsxMagPark__ExceedingMintingLimits();
		if (msg.value != getCurrentStagePrice() * quantity)
			revert SneakerHeadsxMagPark__WrongEthAmount();

		if (_mintOperationHash(msg.sender, quantity, maxQuantity, nonce) != hash)
			revert SneakerHeadsxMagPark__HashComparisonFailed();
		if (!_isTrustedSigner(hash, signature)) revert SneakerHeadsxMagPark__UntrustedSigner();
		if (s_usedNonces[nonce]) revert SneakerHeadsxMagPark__SignatureAlreadyUsed();

		s_numberMintedDuringSaleStage[saleStage][msg.sender] += quantity;
		s_usedNonces[nonce] = true;

		_safeMint(msg.sender, quantity);
	}

	function reserveTeamTokens(address to) external onlyManager {
		if (s_teamTokensReserved) revert SneakerHeadsxMagPark__TeamTokensAlreadyReserved();

		s_teamTokensReserved = true;
		_safeMint(to, TEAM_TOKENS_COUNT);
	}

	/**
	 * @dev This function is used for withdrawing money from the contract
	 *
	 * @param to Address to withdraw money to
	 */
	function withdrawMoney(address payable to) external onlyManager nonReentrant {
		if (address(this).balance == 0) revert SneakerHeadsxMagPark__NothingToWithdraw();
		to.transfer(address(this).balance);
	}

	/**
	 * @dev This function is used for setting base token URI
	 *
	 * @param baseURI New base token URI
	 */
	function setBaseURI(string calldata baseURI) external onlyManager {
		s_baseTokenURI = baseURI;
	}

	// Overrides for marketplace restrictions
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public override onlyAllowedOperator(from) {
		super.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public override onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory data
	) public override onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId, data);
	}

	/**
	 * @dev This function is used for getting the number of tokens minted by a wallet during the sale stage
	 *
	 * @param saleStage Sale stage to get the number of tokens minted by a wallet during
	 * @param owner Wallet to get the number of tokens minted by
	 *
	 * @return Number of tokens minted by the wallet during the sale stage
	 */
	function numberMinted(SALE_STAGE saleStage, address owner) public view returns (uint256) {
		return s_numberMintedDuringSaleStage[saleStage][owner];
	}

	/**
	 * @dev This function is used for getting the current sale stage
	 *
	 * @return Current sale stage
	 */
	function getCurrentSaleStage() public view returns (SALE_STAGE) {
		if (block.timestamp >= SALES_END_TIME) return SALE_STAGE.ENDED;
		if (block.timestamp >= PUBLIC_SALE_START_TIME) return SALE_STAGE.PUBLIC;
		if (block.timestamp >= ALLOWLIST_SALE_START_TIME) return SALE_STAGE.ALLOWLIST;
		if (block.timestamp >= VIP_SALE_START_TIME) return SALE_STAGE.VIP;
		return SALE_STAGE.CLOSED;
	}

	/**
	 * @dev This function is used for getting the current token price
	 *
	 * @return Token price at the current sale stage in wei
	 */
	function getCurrentStagePrice() public view returns (uint256) {
		SALE_STAGE saleStage = getCurrentSaleStage();
		if (saleStage == SALE_STAGE.CLOSED) revert SneakerHeadsxMagPark__SalesAreClosed();
		if (saleStage == SALE_STAGE.ENDED) revert SneakerHeadsxMagPark__SalesHaveEnded();

		if (saleStage == SALE_STAGE.VIP) return VIP_SALE_PRICE;
		if (saleStage == SALE_STAGE.ALLOWLIST) return ALLOWLIST_SALE_PRICE;
		return PUBLIC_SALE_PRICE;
	}

	/**
	 * @dev This function is used for getting VIP sale start time
	 *
	 * @return VIP sale start time in unix time
	 */
	function getVipSaleStartTime() public pure returns (uint32) {
		return VIP_SALE_START_TIME;
	}

	/**
	 * @dev This function is used for getting allowlist sale start time
	 *
	 * @return Allowlist sale start time in unix time
	 */
	function getAllowlistSaleStartTime() public pure returns (uint32) {
		return ALLOWLIST_SALE_START_TIME;
	}

	/**
	 * @dev This function is used for getting public sale start time
	 *
	 * @return Public sale start time in unix time
	 */
	function getPublicSaleStartTime() public pure returns (uint32) {
		return PUBLIC_SALE_START_TIME;
	}

	/**
	 * @dev This function is used for getting sales end time
	 *
	 * @return Sales end time in unix time
	 */
	function getSalesEndTime() public pure returns (uint32) {
		return SALES_END_TIME;
	}

	/**
	 * @dev This function is used for getting VIP sale price
	 *
	 * @return VIP sale price in wei
	 */
	function getVipSalePrice() public pure returns (uint256) {
		return VIP_SALE_PRICE;
	}

	/**
	 * @dev This function is used for getting allowlist sale price
	 *
	 * @return Allowlist sale price in wei
	 */
	function getAllowlistSalePrice() public pure returns (uint256) {
		return ALLOWLIST_SALE_PRICE;
	}

	/**
	 * @dev This function is used for getting public sale price
	 *
	 * @return Public sale price in wei
	 */
	function getPublicSalePrice() public pure returns (uint256) {
		return PUBLIC_SALE_PRICE;
	}

	/**
	 * @dev This function is used for getting the data, needed for signature generation
	 *
	 * @return hashSalt Hash salt for signature generation
	 * @return signerAddress Address of the wallet, generating signatures
	 */
	function getSignatureData() public pure returns (bytes8 hashSalt, address signerAddress) {
		return (HASH_SALT, SIGNER_ADDRESS);
	}

	/**
	 * @dev This function is used for getting URI with collection metadata for OpenSea
	 *
	 * @return URI with collection metadata for OpenSea
	 */
	function contractURI() public pure returns (string memory) {
		return "ipfs://Qmer8aJu1iWmXWkxjUMDXX6uPvAkDcMy8Rn2yy1vV3NDbF";
	}

	/**
	 * @dev This function is used for generating a hash for a mint operation to be signed by a trusted address
	 *
	 * @param buyer Buyer address
	 * @param quantity Number of tokens to mint
	 * @param maxTokens Maximum number of tokens to mint
	 * @param nonce Nonce to prevent replay attacks
	 *
	 * @return Hash for a mint operation to be signed by a trusted address
	 */
	function _mintOperationHash(
		address buyer,
		uint256 quantity,
		uint64 maxTokens,
		uint64 nonce
	) internal view returns (bytes32) {
		SALE_STAGE saleStage = getCurrentSaleStage();
		if (saleStage == SALE_STAGE.CLOSED) revert SneakerHeadsxMagPark__SalesAreClosed();
		if (saleStage == SALE_STAGE.ENDED) revert SneakerHeadsxMagPark__SalesHaveEnded();

		return
			keccak256(
				abi.encodePacked(
					HASH_SALT,
					buyer,
					uint64(block.chainid),
					uint64(saleStage),
					uint64(maxTokens),
					uint64(quantity),
					uint64(nonce)
				)
			);
	}

	/**
	 * @dev This function is used for getting the starting index for the token IDs
	 *
	 * @return Starting index for the token IDs
	 */
	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	/**
	 * @dev This function is used for getting the base URI for token metadata
	 *
	 * @return Base URI for token metadata
	 */
	function _baseURI() internal view virtual override returns (string memory) {
		return s_baseTokenURI;
	}

	/**
	 * @dev This function is used for checking if a signature is signed by a trusted address
	 *
	 * @param hash Hash to check the signature for
	 * @param signature Signature to check
	 *
	 * @return True if the signature is signed by a trusted address, false otherwise
	 */
	function _isTrustedSigner(bytes32 hash, bytes memory signature) internal pure returns (bool) {
		return SIGNER_ADDRESS == ECDSA.recover(hash, signature);
	}
}