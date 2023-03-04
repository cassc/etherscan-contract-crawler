// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "./apis/NFTMarketRouterAPIs.sol";

error NFTMarketRouterList_Token_Ids_Not_Set();
error NFTMarketRouterList_Must_Set_Reserve_Or_Buy_Price();
error NFTMarketRouterList_Exhibition_Id_Set_Without_Reserve_Price();
error NFTMarketRouterList_Buy_Price_Set_But_Should_Set_Buy_Price_Is_False();

/**
 * @title Offers value-added functions for listing NFTs in the NFTMarket contract.
 * @author batu-inal & HardlyDifficult & reggieag
 */
abstract contract NFTMarketRouterList is NFTMarketRouterAPIs {
  /**
   * @notice Batch create reserve auction and/or set a buy price for many NFTs and escrow in the market contract.
   * A reserve auction price and/or a buy price must be set.
   * @param nftContract The address of the NFT contract.
   * @param tokenIds The ids of NFTs from the collection to set prices for.
   * @param exhibitionId The id of the exhibition the auctions are to be listed with.
   * Set this to 0 if n/a. Only applies to creating auctions.
   * @param reservePrice The initial reserve price for the auctions created.
   * Set the reservePrice to 0 to skip creating auctions.
   * @param shouldSetBuyPrice True if buy prices should be set for these NFTs.
   * Set this to false to skip setting buy prices. 0 is a valid buy price enabling a giveaway.
   * @param buyPrice The price at which someone could buy these NFTs.
   * @return firstAuctionIdOfSequence 0 if reservePrice is 0, otherwise this is the id of the first auction listed.
   * The other auctions in the batch are listed sequentially from `first id` to `first id + count`.
   * @dev Notes:
   *   a) Approval should be granted for the NFTMarket contract before using this function.
   *   b) If any NFT is already listed for auction then the entire batch call will revert.
   */
  function batchListFromCollection(
    address nftContract,
    uint256[] calldata tokenIds,
    uint256 exhibitionId,
    uint256 reservePrice,
    bool shouldSetBuyPrice,
    uint256 buyPrice
  ) external returns (uint256 firstAuctionIdOfSequence) {
    // Validate input.
    if (tokenIds.length == 0) {
      revert NFTMarketRouterList_Token_Ids_Not_Set();
    }
    if (!shouldSetBuyPrice && buyPrice != 0) {
      revert NFTMarketRouterList_Buy_Price_Set_But_Should_Set_Buy_Price_Is_False();
    }

    // List NFTs for sale.
    if (reservePrice != 0) {
      // Create auctions.

      // Process the first NFT in order to capture that auction ID as the return value.
      firstAuctionIdOfSequence = _createReserveAuctionV2(nftContract, tokenIds[0], reservePrice, exhibitionId);
      if (shouldSetBuyPrice) {
        // And set buy prices.
        _setBuyPrice(nftContract, tokenIds[0], buyPrice);
      }

      for (uint256 i = 1; i < tokenIds.length; ) {
        _createReserveAuctionV2(nftContract, tokenIds[i], reservePrice, exhibitionId);
        if (shouldSetBuyPrice) {
          _setBuyPrice(nftContract, tokenIds[i], buyPrice);
        }
        unchecked {
          ++i;
        }
      }
    } else {
      // Set buy prices only (no auctions).

      if (exhibitionId != 0) {
        // Exhibitions are only for auctions ATM.
        revert NFTMarketRouterList_Exhibition_Id_Set_Without_Reserve_Price();
      }
      if (!shouldSetBuyPrice) {
        revert NFTMarketRouterList_Must_Set_Reserve_Or_Buy_Price();
      }

      for (uint256 i = 0; i < tokenIds.length; ) {
        _setBuyPrice(nftContract, tokenIds[i], buyPrice);
        unchecked {
          ++i;
        }
      }
    }
  }
}