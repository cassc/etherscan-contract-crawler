// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IMarketplace {
	struct Offer {
		address seller;
		address buyer;
		address collection;
		uint256 assetId;
		address token;
		uint256 price;
		uint256 buyerAcceptStatus;
		uint256 sellerAcceptStatus;
		uint256 status;
	}
}