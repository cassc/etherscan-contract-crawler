// SPDX-License-Identifier: MIT
// 20220612 j0zf - Market
// 2021-02-25 Media Library for CryptoStacks - j0zf
// 2020-07-06 MediaTokens Library for CryptoMedia - j0zf

pragma solidity >=0.6.0 <0.8.0;

library Market {

	// Status Types
	uint32 constant _Open_ = 1;
	uint32 constant _Complete_ = 2;
	uint32 constant _Cancelled_ = 3;

	// Listing Types
	uint32 constant _Mintable_ = 1;
	uint32 constant _Sale_  = 2;
	uint32 constant _Bid_  = 3;
	uint32 constant _DutchAuction_  = 4;
	uint32 constant _EnglishAuction_  = 5;
	uint32 constant _Trade_  = 6;
	uint32 constant _ClaimCode_  = 7;
	uint32 constant _Free_  = 8;

	struct TokenContract {
		string name;
		address location;
		uint32 contractType;
	}

	struct Listing {
		uint256 contractId;
		address owner;
		uint32 listingType;
		uint32 status;
	}

}
