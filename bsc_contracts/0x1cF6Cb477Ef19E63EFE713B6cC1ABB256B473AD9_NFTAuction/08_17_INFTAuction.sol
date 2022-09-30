// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTAuction {

    struct Auction {
        address token;
        uint256 tokenId;
        address payable seller;
        PayMethod payMethod;
        address payable bidder;
        uint256 price;
        bool finished;
        uint256 expiration;
    }

    enum PayMethod {
        PAY_BNB,
        PAY_BUSD,
        PAY_BIB
    }

    event CreateAuction(uint256 auctionId, address seller, address token, uint256 tokenId, PayMethod payMethod, uint256 minPrice, uint256 expiration);
    event Bid(uint256 auctionId, address bidder, uint256 price);
    event FinishAuction(uint256 auctionId, address seller, address token, uint256 tokenId, address bidder, PayMethod payMethod, uint256 price, uint256 expiration, uint256 fee);
    event CancelAuction(uint256 auctionId, address operator);

    function setRoyaltyRatio(uint feeRatio) external;

    function setFeeRatio(uint feeRatio) external;

    function isOriginOwner(address token, uint tokenId, address owner) external view returns(bool);

    // check if a token has a Auction to connected
    function hasAuction(address token,  uint tokenId) external view returns(bool);

    // return the Auction opened to the tokenId
    function getAuction(address token,  uint tokenId) external view returns(Auction memory);

    function createAuction(address token, uint256 tokenId, PayMethod payMethod, uint256 minPrice, uint256 expiration) external;

    function bid(uint256 auctionId, uint256 price) external payable;

    function finishAuction(uint256 auctionId) external;

    function cancelAuction(uint256 auctionId) external;
}