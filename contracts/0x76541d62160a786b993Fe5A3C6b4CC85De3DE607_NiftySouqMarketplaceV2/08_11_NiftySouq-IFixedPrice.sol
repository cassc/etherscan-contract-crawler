// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface NiftySouqIFixedPrice {
    struct PurchaseOffer {
        address offeredBy;
        uint256 quantity;
        uint256 price;
        uint256 offeredAt;
        bool canceled;
    }

    struct Sale {
        uint256 tokenId;
        address tokenContract;
        bool isERC1155;
        uint256 quantity;
        uint256 price;
        address seller;
        uint256 createdAt;
        uint256 soldQuantity;
        address[] buyer;
        uint256[] purchaseQuantity;
        uint256[] soldAt;
        bool isBargainable;
        PurchaseOffer[] offers;
    }

    struct SellData {
        uint256 offerId;
        uint256 tokenId;
        address tokenContract;
        bool isERC1155;
        uint256 quantity;
        uint256 price;
        address seller;
        bool isBargainable;
    }

    struct LazyMintData {
        uint256 offerId;
        uint256 tokenId;
        address tokenContract;
        bool isERC1155;
        uint256 quantity;
        uint256 price;
        address seller;
        uint256 soldQuantity;
        address buyer;
        uint256 purchaseQuantity;
        address[] investors;
        uint256[] revenues;
    }

    struct BuyNFT {
        uint256 offerId;
        address buyer;
        uint256 quantity;
        uint256 payment;
    }

    struct Payout {
        address seller;
        address buyer;
        uint256 tokenId;
        address tokenAddress;
        uint256 quantity;
        address[] refundAddresses;
        uint256[] refundAmount;
        bool soldout;
    }

    function sell(SellData calldata sell_) external;

    function lazyMint(LazyMintData calldata lazyMintData_)
        external
        returns (
            address[] memory recipientAddresses_,
            uint256[] memory paymentAmount_
        );

    function updateSalePrice(uint256 offerId_, uint256 updatedPrice_, address seller_) external;

    function makeOffer(
        uint256 offerId_,
        address offeredBy,
        uint256 quantity,
        uint256 offerPrice
    ) external returns (uint256 offerIdx_);

    function cancelOffer(
        uint256 offerId,
        address offeredBy,
        uint256 offerIdx_
    )
        external
        returns (
            address[] memory refundAddresses_,
            uint256[] memory refundAmount_
        );

    function buyNft(BuyNFT calldata buyNft_)
        external
        returns (Payout memory payout_);

    function acceptOffer(
        uint256 offerId_,
        address seller_,
        uint256 offerIdx_
    ) external returns (Payout memory payout_);

    function getSaleDetails(uint256 offerId_)
        external
        view
        returns (Sale memory sale_);
}