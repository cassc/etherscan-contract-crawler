// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {INFTEDA} from "./interfaces/INFTEDA.sol";
import {EDAPrice} from "./libraries/EDAPrice.sol";

abstract contract NFTEDA is INFTEDA {
    using SafeTransferLib for ERC20;

    error AuctionExists();
    error InvalidAuction();
    /// @param received The amount of payment received
    /// @param expected The expected payment amount
    error InsufficientPayment(uint256 received, uint256 expected);
    /// @param currentPrice The current auction price
    /// @param maxPrice The passed max price the purchaser is willing to pay
    error MaxPriceTooLow(uint256 currentPrice, uint256 maxPrice);

    /// @inheritdoc INFTEDA
    function auctionCurrentPrice(INFTEDA.Auction calldata auction) public view virtual returns (uint256) {
        uint256 id = auctionID(auction);
        uint256 startTime = auctionStartTime(id);
        if (startTime == 0) {
            revert InvalidAuction();
        }

        return _auctionCurrentPrice(id, startTime, auction);
    }

    /// @inheritdoc INFTEDA
    function auctionID(INFTEDA.Auction memory auction) public pure virtual returns (uint256) {
        return uint256(keccak256(abi.encode(auction)));
    }

    /// @inheritdoc INFTEDA
    function auctionStartTime(uint256 id) public view virtual returns (uint256);

    /// @notice Creates an auction defined by the passed `auction`
    /// @dev assumes the nft being sold is already controlled by the auction contract
    /// @dev does no validation the auction, aside that it does not exist.
    /// @dev if paymentAsset = address(0), purchase will not revert
    /// @param auction The defintion of the auction
    /// @return id the id of the auction
    function _startAuction(INFTEDA.Auction memory auction) internal virtual returns (uint256 id) {
        id = auctionID(auction);

        if (auctionStartTime(id) != 0) {
            revert AuctionExists();
        }

        _setAuctionStartTime(id);

        emit StartAuction(
            id,
            auction.auctionAssetID,
            auction.auctionAssetContract,
            auction.nftOwner,
            auction.perPeriodDecayPercentWad,
            auction.secondsInPeriod,
            auction.startPrice,
            auction.paymentAsset
            );
    }

    /// @notice purchases the NFT being sold in `auction`, reverts if current auction price exceed maxPrice
    /// @param auction The auction selling the NFT
    /// @param maxPrice The maximum the caller is willing to pay
    function _purchaseNFT(INFTEDA.Auction memory auction, uint256 maxPrice, address sendTo)
        internal
        virtual
        returns (uint256 startTime, uint256 price)
    {
        uint256 id;
        (id, startTime, price) = _checkAuctionAndReturnDetails(auction);

        if (price > maxPrice) {
            revert MaxPriceTooLow(price, maxPrice);
        }

        _clearAuctionState(id);

        auction.auctionAssetContract.safeTransferFrom(address(this), sendTo, auction.auctionAssetID);

        auction.paymentAsset.safeTransferFrom(msg.sender, address(this), price);

        emit EndAuction(id, price);
    }

    function _checkAuctionAndReturnDetails(INFTEDA.Auction memory auction)
        internal
        view
        returns (uint256 id, uint256 startTime, uint256 price)
    {
        id = auctionID(auction);
        startTime = auctionStartTime(id);

        if (startTime == 0) {
            revert InvalidAuction();
        }
        price = _auctionCurrentPrice(id, startTime, auction);
    }

    /// @notice Sets the time at which the auction was started
    /// @dev abstracted to a function to allow developer some freedom with how to store auction state
    /// @param id The id of the auction
    function _setAuctionStartTime(uint256 id) internal virtual;

    /// @notice Clears all stored state for the auction
    /// @dev abstracted to a function to allow developer some freedom with how to store auction state
    /// @param id The id of the auction
    function _clearAuctionState(uint256 id) internal virtual;

    /// @notice Returns the current price of the passed auction, reverts if no such auction exists
    /// @dev startTime is passed, optimized for cases where the auctionId has already been computed
    /// @dev and startTime looked it up
    /// @param id The ID of the auction
    /// @param startTime The start time of the auction
    /// @param auction The auction for which the caller wants to know the current price
    /// @return price the current amount required to purchase the NFT being sold in this auction
    function _auctionCurrentPrice(uint256 id, uint256 startTime, INFTEDA.Auction memory auction)
        internal
        view
        virtual
        returns (uint256)
    {
        return EDAPrice.currentPrice(
            auction.startPrice, block.timestamp - startTime, auction.secondsInPeriod, auction.perPeriodDecayPercentWad
        );
    }
}