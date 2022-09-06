//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface INFTAuction {
  //Each Auction is unique to each NFT (contract + id pairing).
  struct Auction {
    //map token ID to
    uint32 bidIncreasePercentage;
    uint32 auctionBidPeriod; //Increments the length of time the auction is open in which a new bid can be made after each bid.
    uint64 auctionEnd;
    uint128 minPrice;
    uint128 buyNowPrice;
    uint128 nftHighestBid;
    address nftHighestBidder;
    address nftSeller;
    address whitelistedBuyer; //The seller can specify a whitelisted address for a sale (this is effectively a direct sale).
    address nftRecipient; //The bidder can specify a recipient for the NFT if their bid is successful.
    address ERC20Token; // The seller can specify an ERC20 token that can be used to bid or purchase the NFT.
    address[] feeRecipients;
    uint32[] feePercentages;
  }

  // ===> Events

  event NftAuctionCreated(
    address nftContractAddress,
    uint256 tokenId,
    address nftSeller,
    address erc20Token,
    uint128 minPrice,
    uint128 buyNowPrice,
    uint32 auctionBidPeriod,
    uint32 bidIncreasePercentage,
    address[] feeRecipients,
    uint32[] feePercentages
  );

  event SaleCreated(
    address nftContractAddress,
    uint256 tokenId,
    address nftSeller,
    address erc20Token,
    uint128 buyNowPrice,
    address whitelistedBuyer,
    address[] feeRecipients,
    uint32[] feePercentages
  );

  event BidMade(
    address nftContractAddress,
    uint256 tokenId,
    address bidder,
    uint256 ethAmount,
    address erc20Token,
    uint256 tokenAmount
  );

  event AuctionPeriodUpdated(address nftContractAddress, uint256 tokenId, uint64 auctionEndPeriod);

  event NFTTransferredAndSellerPaid(
    address nftContractAddress,
    uint256 tokenId,
    address nftSeller,
    uint128 nftHighestBid,
    address nftHighestBidder,
    address nftRecipient
  );

  event AuctionSettled(address nftContractAddress, uint256 tokenId, address auctionSettler);

  event AuctionWithdrawn(address nftContractAddress, uint256 tokenId, address nftOwner);

  event BidWithdrawn(address nftContractAddress, uint256 tokenId, address highestBidder);

  event WhitelistedBuyerUpdated(
    address nftContractAddress,
    uint256 tokenId,
    address newWhitelistedBuyer
  );

  event MinimumPriceUpdated(address nftContractAddress, uint256 tokenId, uint256 newMinPrice);

  event BuyNowPriceUpdated(address nftContractAddress, uint256 tokenId, uint128 newBuyNowPrice);
  event HighestBidTaken(address nftContractAddress, uint256 tokenId);

  // ===> End Of Events
}