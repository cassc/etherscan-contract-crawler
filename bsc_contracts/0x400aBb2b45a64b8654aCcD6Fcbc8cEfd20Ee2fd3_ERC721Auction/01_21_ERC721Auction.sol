// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import "./ERC721AuctionBase.sol";

contract ERC721Auction is ERC721AuctionBase {
    using ArrayLibrary for address[];
    using ArrayLibrary for uint256[];

    function createAuction(
        address contractAddr,
        uint256 tokenId,
        uint8 payment
    ) external isProperContract(contractAddr) {
        IERC721(contractAddr).transferFrom(msg.sender, address(this), tokenId);
        tokenIdToAuctions[contractAddr][tokenId] = Auction(
            payment,
            msg.sender,
            new address[](0),
            new uint256[](0)
        );
        auctionTokenIds[contractAddr].push(tokenId);
        auctionTokenIdsBySeller[msg.sender][contractAddr].push(tokenId);
        emit AuctionCreated(contractAddr, tokenId, payment, msg.sender);
    }

    function bid(
        address contractAddr,
        uint256 tokenId,
        uint256 price
    ) external payable isProperContract(contractAddr) {
        Auction storage auction = tokenIdToAuctions[contractAddr][tokenId];
        require(auction.auctioneer != address(0), "Not On Auction");
        require(auction.auctioneer != msg.sender, "Is Auctioneer");
        require(
            auction.bidders.findIndex(msg.sender) == auction.bidders.length,
            "Has Bid"
        );
        PaymentLibrary.escrowFund(tokenAddrs[auction.payment], price);
        auction.bidders.push(msg.sender);
        auction.bidPrices.push(price);
        emit AuctionBid(contractAddr, tokenId, msg.sender, price);
    }

    function cancelBid(address contractAddr, uint256 tokenId)
        external
        isProperContract(contractAddr)
    {
        Auction storage auction = tokenIdToAuctions[contractAddr][tokenId];
        require(auction.auctioneer != address(0), "Not On Auction");
        uint256 i = auction.bidders.findIndex(msg.sender);
        require(i < auction.bidders.length, "No Bid");
        PaymentLibrary.transferFund(
            tokenAddrs[auction.payment],
            auction.bidPrices[i],
            auction.bidders[i]
        );
        auction.bidders.removeAt(i);
        auction.bidPrices.removeAt(i);
        emit BidCancelled(contractAddr, tokenId, msg.sender);
    }

    function cancelAuction(address contractAddr, uint256 tokenId)
        external
        payable
        isProperContract(contractAddr)
    {
        Auction memory auction = tokenIdToAuctions[contractAddr][tokenId];
        require(auction.auctioneer != address(0), "Not On Auction");
        require(auction.auctioneer == msg.sender, "Not Auctioneer");
        IERC721(contractAddr).transferFrom(address(this), msg.sender, tokenId);
        _cancelAuction(contractAddr, tokenId);
        emit AuctionCancelled(contractAddr, tokenId, msg.sender);
    }

    function acceptBid(address contractAddr, uint256 tokenId)
        external
        isProperContract(contractAddr)
    {
        Auction storage auction = tokenIdToAuctions[contractAddr][tokenId];
        require(auction.auctioneer != address(0), "Not On Auction");
        require(auction.bidders.length > 0, "No Bid");
        require(auction.auctioneer == msg.sender, "Not Auctioneer");
        uint256 maxBidderId = auction.bidPrices.findMaxIndex();
        address bidder = auction.bidders[maxBidderId];
        uint256 bidPrice = auction.bidPrices[maxBidderId];
        uint8 payment = auction.payment;
        PaymentLibrary.payFund(
            tokenAddrs[payment],
            bidPrice,
            msg.sender,
            royaltyAddr,
            royaltyPercent,
            contractAddr,
            tokenId
        );
        IERC721(contractAddr).transferFrom(address(this), bidder, tokenId);
        auction.bidders.removeAt(maxBidderId);
        auction.bidPrices.removeAt(maxBidderId);
        _cancelAuction(contractAddr, tokenId);
        emit BidAccepted(contractAddr, tokenId, payment, bidder, bidPrice);
    }
}