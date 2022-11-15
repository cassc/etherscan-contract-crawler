// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./MarketplaceBase.sol";

abstract contract ERC721AuctionBase is MarketplaceBase {
    using ArrayLibrary for uint256[];

    struct Auction {
        uint8 payment;
        address auctioneer;
        address[] bidders;
        uint256[] bidPrices;
    }

    mapping(address => uint256[]) internal auctionTokenIds;
    mapping(address => mapping(address => uint256[]))
        internal auctionTokenIdsBySeller;

    mapping(address => mapping(uint256 => Auction)) internal tokenIdToAuctions;

    event AuctionCreated(
        address contractAddr,
        uint256 tokenId,
        uint8 payment,
        address auctioneer
    );
    event AuctionCancelled(
        address contractAddr,
        uint256 tokenId,
        address auctioneer
    );
    event AuctionBid(
        address contractAddr,
        uint256 tokenId,
        address bidder,
        uint256 bidPrice
    );
    event BidAccepted(
        address contractAddr,
        uint256 tokenId,
        uint8 payment,
        address bidder,
        uint256 bidPrice
    );
    event BidCancelled(address contractAddr, uint256 tokenId, address bidder);

    function _cancelAuction(address contractAddr, uint256 tokenId) internal {
        Auction memory auction = tokenIdToAuctions[contractAddr][tokenId];
        for (uint256 i; i < auction.bidders.length; ++i) {
            claimable[auction.bidders[i]][auction.payment] += auction.bidPrices[
                i
            ];
        }
        delete tokenIdToAuctions[contractAddr][tokenId];
        auctionTokenIds[contractAddr].remove(tokenId);
        auctionTokenIdsBySeller[msg.sender][contractAddr].remove(tokenId);
    }

    function getAuctions(address contractAddr)
        external
        view
        isProperContract(contractAddr)
        returns (Auction[] memory auctions)
    {
        uint256 length = auctionTokenIds[contractAddr].length;
        auctions = new Auction[](length);
        for (uint256 i; i < length; ++i) {
            auctions[i] = tokenIdToAuctions[contractAddr][
                auctionTokenIds[contractAddr][i]
            ];
        }
    }

    function getAuctionsBySeller(address contractAddr, address seller)
        external
        view
        isProperContract(contractAddr)
        returns (Auction[] memory auctions)
    {
        uint256 length = auctionTokenIdsBySeller[seller][contractAddr].length;
        auctions = new Auction[](length);
        for (uint256 i; i < length; ++i) {
            auctions[i] = tokenIdToAuctions[contractAddr][
                auctionTokenIdsBySeller[seller][contractAddr][i]
            ];
        }
    }
}