//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.10;

library TokenStructLib {
	using TokenStructLib for TokenInfo;

	struct TokenInfo {
		uint256 tokenId;
		uint256 totalSell;
		uint256 minPrice;
		uint256 thirdPartyFee;
		uint256 galleryOwnerFee;
		uint256 artistFee;
		uint256 thirdPartyFeeExpiryTime;
		address payable gallery;
		address payable thirdParty;
		// address payable artist;
		address nftOwner;
		bool onSell;
		bool USD;
		bool onAuction;
		address payable galleryOwner;
	}
}