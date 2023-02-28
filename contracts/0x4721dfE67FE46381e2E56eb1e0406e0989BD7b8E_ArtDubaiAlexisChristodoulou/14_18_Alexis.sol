// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
	    :::     :::::::::      :::      ::::::::  
	  :+: :+:   :+:    :+:   :+: :+:   :+:    :+: 
	 +:+   +:+  +:+    +:+  +:+   +:+  +:+        
	+#++:++#++: +#+    +:+ +#++:++#++: +#+        
	+#+     +#+ +#+    +#+ +#+     +#+ +#+        
	#+#     #+# #+#    #+# #+#     #+# #+#    #+# 
	###     ### #########  ###     ###  ########  

    UAE NFT - Art Dubai | Alexis Christodoulou
    All rights reserved 2023
    Developed by DeployLabs.io ([email protected])
*/

import "./ArtDubai.sol";

error Alexis__EmptyVouchersArray();
error Alexis__VoucherAlreadyUsed();

error Alexis__HashComparisonFailed();
error Alexis__SignatureExpired();
error Alexis__UntrustedSigner();
error Alexis__SignatureAlreadyUsed();

/**
 * @title UAE NFT - Art Dubai | Alexis Christodoulou
 * @author DeployLabs.io
 *
 * @dev This contract is a collection for Art Dubai by Alexis Christodoulou.
 */
contract ArtDubaiAlexisChristodoulou is ArtDubai {
	/**
	 * @dev A signature package, that secures the minting of reward tokens.
	 *
	 * @param hash The hash of the minting operation.
	 * @param signature The signature for the hash.
	 * @param signatureValidUntil The timestamp until which the signature is valid.
	 * @param nonce The nonce, that is used to prevent replay attacks.
	 */
	struct RewardSignaturePackage {
		bytes32 hash;
		bytes signature;
		uint32 signatureValidUntil;
		uint64 nonce;
	}

	/**
	 * @dev A voucher, that can be used to mint reward tokens.
	 *
	 * @param collection The collection address.
	 * @param tokenId The token ID.
	 */
	struct RewardVoucher {
		address collection;
		uint64 tokenId;
	}

	event RewardVoucherUsed(address indexed collection, uint256 indexed tokenId);

	uint8 private s_daytimeRewardTokenId;
	uint8 private s_nighttimeRewardTokenId;

	// Collection address to token ID to used/unused
	mapping(address => mapping(uint256 => bool)) private s_tokenIdsUsedForRewards;

	constructor() ArtDubai(0xaca187d2a59b04b4, 0x89994365E8538F61a906c84cb15B6d415051fed0) {}

	/**
	 * @dev Mint reward tokens for the caller.
	 *
	 * @param signaturePackage The signature package.
	 * @param rewardVouchers The reward vouchers to use.
	 */
	function mintRewardTokens(
		RewardSignaturePackage calldata signaturePackage,
		RewardVoucher[] calldata rewardVouchers
	) external {
		if (rewardVouchers.length == 0) revert Alexis__EmptyVouchersArray();

		uint8 tokenIdToMint = _itIsDaytime() ? s_daytimeRewardTokenId : s_nighttimeRewardTokenId;

		for (uint16 i = 0; i < rewardVouchers.length; i++) {
			RewardVoucher memory rewardVoucher = rewardVouchers[i];
			if (s_tokenIdsUsedForRewards[rewardVoucher.collection][rewardVoucher.tokenId])
				revert Alexis__VoucherAlreadyUsed();

			s_tokenIdsUsedForRewards[rewardVoucher.collection][rewardVoucher.tokenId] = true;
			emit RewardVoucherUsed(rewardVoucher.collection, rewardVoucher.tokenId);
		}

		if (signaturePackage.signatureValidUntil < block.timestamp) revert Alexis__SignatureExpired();
		if (!_isCorrectRewardMintOperationHash(signaturePackage, rewardVouchers, msg.sender))
			revert Alexis__HashComparisonFailed();
		if (!_isTrustedSigner(signaturePackage.hash, signaturePackage.signature))
			revert Alexis__UntrustedSigner();
		if (s_usedNonces[signaturePackage.nonce]) revert Alexis__SignatureAlreadyUsed();

		s_numberMinted[tokenIdToMint][msg.sender] += uint16(rewardVouchers.length);
		s_usedNonces[signaturePackage.nonce] = true;

		_mint(msg.sender, tokenIdToMint, rewardVouchers.length, "");
	}

	/**
	 * @dev Specify which token IDs are going to be used as reward tokens.
	 *
	 * @param daytimeRewardTokenId The daytime reward token ID.
	 * @param nighttimeRewardTokenId The nighttime reward token ID.
	 */
	function setRewardTokenIds(
		uint8 daytimeRewardTokenId,
		uint8 nighttimeRewardTokenId
	) external onlyOwner {
		s_daytimeRewardTokenId = daytimeRewardTokenId;
		s_nighttimeRewardTokenId = nighttimeRewardTokenId;
	}

	/**
	 * @dev Get the reward token ID.
	 *
	 * @return daytimeRewardTokenId The daytime reward token ID.
	 * @return nighttimeRewardTokenId The nighttime reward token ID.
	 */
	function getRewardTokenIds()
		public
		view
		returns (uint8 daytimeRewardTokenId, uint8 nighttimeRewardTokenId)
	{
		daytimeRewardTokenId = s_daytimeRewardTokenId;
		nighttimeRewardTokenId = s_nighttimeRewardTokenId;
	}

	/// @inheritdoc ArtDubai
	function isTokenForSale(uint8 tokenId) public view override returns (bool isForSale) {
		isForSale =
			(tokenId != s_daytimeRewardTokenId) &&
			(tokenId != s_nighttimeRewardTokenId) &&
			super.isTokenForSale(tokenId);
	}

	/**
	 * @dev Check if it's daytime in Dubai (GMT+4).
	 *
	 * @return isDaytime True if it's daytime in Dubai.
	 */
	function _itIsDaytime() internal view returns (bool isDaytime) {
		// Dubai is GMT+4, thus we add 14400 seconds to the current timestamp
		uint256 hour = ((block.timestamp + 14400) % 86400) / 3600;
		isDaytime = (hour >= 6) && (hour < 18);
	}

	/**
	 * @dev Check whether a message hash is the one that has been signed.
	 *
	 * @param signaturePackage The signature package.
	 * @param mintTo The address to mint to.
	 *
	 * @return isCorrectRewardMintOperationHash Whether the message hash matches the one that has been signed.
	 */
	function _isCorrectRewardMintOperationHash(
		RewardSignaturePackage calldata signaturePackage,
		RewardVoucher[] calldata rewardVouchers,
		address mintTo
	) internal view returns (bool isCorrectRewardMintOperationHash) {
		bytes memory collectionBytes;
		bytes memory tokenIdBytes;

		for (uint16 i = 0; i < rewardVouchers.length; i++) {
			collectionBytes = abi.encodePacked(collectionBytes, rewardVouchers[i].collection);
			tokenIdBytes = abi.encodePacked(tokenIdBytes, rewardVouchers[i].tokenId);
		}

		bytes memory message = abi.encodePacked(
			i_hashSalt,
			mintTo,
			uint64(block.chainid),
			collectionBytes,
			tokenIdBytes,
			signaturePackage.signatureValidUntil,
			signaturePackage.nonce
		);
		bytes32 messageHash = keccak256(message);

		isCorrectRewardMintOperationHash = messageHash == signaturePackage.hash;
	}
}