// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/**
	This struct contains the data and configuration of the Bonkler auction 
	contract.

	@param bidder The address of the current highest bidder.
	@param amount Tha current highest bid amount.
	@param withdrawable The amount of Ether that may be withdrawn by the 
		auction operator.
	@param startTime The start time of the auction.
	@param endTime The end time of the auction.
	@param bonklerId The ID of the next Bonkler generated, starting from one.
	@param generationHashesLength The number of Bonkler generation hashes 
		loaded into the contract.
	@param settled Whether or not the contract's auction has been settled.
	@param reservePercentage The percent of the bid to store in the Bonkler.
	@param bonklers The address of the Bonkler NFT contract.
	@param reservePrice The minimum price accepted in a bid.
	@param bidIncrement The minimum increment of the bid.
	@param duration The duration of a single auction.
	@param timeBuffer The duration within which to extend the auction back to 
		`timeBuffer` duration.
	@param bonklersBalance The amount of ETH in the Bonklers NFT contract. The 
		"treasury" balance.
	@param bonklersTotalRedeemed The total number of Bonklers redeemed for 
		treasury shares.
*/
struct AuctionData {
	address bidder;
	uint96 amount;
	uint96 withdrawable;
	uint40 startTime;
	uint40 endTime;
	uint24 bonklerId;
	uint24 generationHashesLength;
	bool settled;
	uint8 reservePercentage;
	address bonklers;
	uint96 reservePrice;
	uint96 bidIncrement;
	uint32 duration;
	uint32 timeBuffer;
	uint256 bonklersBalance;
	uint256 bonklersTotalRedeemed;
}

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title An interface for the BonklerAuction contract.
	@author Tim Clancy <tim-clancy.eth>

	The BonklerAuction contract manages the daily sale of Bonklers.

	@custom:date April 20th, 2023.
*/
interface IBonklerAuction {

	/**
		Return all public data on the current state of the auction, including 
		useful information regarding the Bonklers NFT itself.

		@return data The current state of the auction.
	*/
	function auctionData () external view returns (AuctionData memory data);

	/**
		Create a bid in Ether for a particular Bonkler.

		@param _bonklerId The ID of the Bonkler to bid on.
		@param _generationHash The generation hash to submit for the Bonkler.
	*/
	function createBid (
		uint256 _bonklerId,
		uint256 _generationHash
	) external payable;
}