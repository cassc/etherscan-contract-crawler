// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interface/NiftySouq-IMarketplaceManager.sol";
import "./interface/NiftySouq-IERC721.sol";
import "./interface/NiftySouq-IERC1155.sol";
import "./interface/NiftySouq-IFixedPrice.sol";
import "./interface/NiftySouq-IAuction.sol";
import "./interface/IERC20.sol";

enum OfferState {
    OPEN,
    CANCELLED,
    ENDED
}

enum OfferType {
    SALE,
    AUCTION
}

struct MintData {
    address tokenAddress;
    string uri;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 quantity;
}

struct LazyMintSellData {
    address tokenAddress;
    string uri;
    address seller;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 minPrice;
    uint256 quantity;
    bytes signature;
}

struct LazyMintAuctionData {
    string uri;
    address seller;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 startTime;
    uint256 duration;
    uint256 startBidPrice;
    uint256 reservePrice;
    bytes signature;
}

struct Offer {
    uint256 tokenId;
    OfferType offerType;
    OfferState status;
    ContractType contractType;
}

struct CreateAuctionData {
    uint256 tokenId;
    address tokenContract;
    uint256 duration;
    uint256 startBidPrice;
    uint256 reservePrice;
}

struct MintAndCreateAuctionData {
    address tokenAddress;
    string uri;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 duration;
    uint256 startBidPrice;
    uint256 reservePrice;
}

struct Payout {
    address currency;
    address[] refundAddresses;
    uint256[] refundAmounts;
}

contract NiftySouqMarketplaceV2 is Initializable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    address private _admin;

    NiftySouqIMarketplaceManager private _niftySouqMarketplaceManager;
    NiftySouqIERC721V2 private _niftySouqErc721;
    NiftySouqIERC1155V2 private _niftySouqErc1155;
    NiftySouqIFixedPrice private _niftySouqFixedPrice;
    NiftySouqIAuction private _niftySouqAuction;

    Counters.Counter private _offerId;
    mapping(uint256 => Offer) private _offers;

    event Mint(
        uint256 tokenId,
        address contractAddress,
        bool isERC1155,
        address owner,
        uint256 quantity
    );

    event FixedPriceSale(
        uint256 offerId,
        uint256 tokenId,
        address contractAddress,
        bool isERC1155,
        address owner,
        uint256 quantity,
        uint256 price
    );
    event UpdateSalePrice(uint256 offerId, uint256 price);
    event CancelSale(uint256 offerId);
    event MakeOffer(
        uint256 offerId,
        uint256 oferIdx,
        address offeredBy,
        uint256 quantity,
        uint256 offerPrice
    );
    event CancelOffer(uint256 offerId, uint256 offerIdx);

    event Purchase(
        uint256 offerId,
        address buyer,
        address currency,
        uint256 quantity,
        bool isSaleCompleted
    );
    
    event AcceptOffer(
        uint256 offerId,
        uint256 offerIdx,
        address buyer,
        address currency,
        uint256 quantity,
        bool isSaleCompleted
    );

    event CreateAuction(
        uint256 offerId,
        uint256 tokenId,
        address contractAddress,
        address owner,
        uint256 startTime,
        uint256 duration,
        uint256 startBidPrice,
        uint256 reservePrice
    );
    event CancelAuction(uint256 offerId);
    event EndAuction(
        uint256 offerId,
        uint256 BidIdx,
        address buyer,
        address currency,
        uint256 price
    );
    event PlaceBid(
        uint256 offerId,
        uint256 BidIdx,
        address bidder,
        uint256 bidAmount
    );
    event PlaceHigherBid(
        uint256 offerId,
        uint256 BidIdx,
        address bidder,
        uint256 bidAmount
    );
    event CancelBid(uint256 offerId, uint256 bidIdx);

    event PayoutTransfer(
        address indexed withdrawer,
        uint256 indexed amount,
        address indexed currency
    );
    event RefundTransfer(address indexed withdrawer, uint256 indexed amount);

    modifier isNiftyAdmin() {
        require(
            (_admin == msg.sender) ||
                (_niftySouqMarketplaceManager.isAdmin(msg.sender)),
            "NiftyMarketplace: unauthorized."
        );
        _;
    }

    function initialize() public initializer {
        _admin = msg.sender;
    }

    function setContractAddresses(
        address marketplaceManager_,
        address erc721_,
        address erc1155_,
        address fixedPrice_,
        address auction_
    ) public isNiftyAdmin {
        if (marketplaceManager_ != address(0))
            _niftySouqMarketplaceManager = NiftySouqIMarketplaceManager(
                marketplaceManager_
            );
        if (erc721_ != address(0))
            _niftySouqErc721 = NiftySouqIERC721V2(erc721_);
        if (erc1155_ != address(0))
            _niftySouqErc1155 = NiftySouqIERC1155V2(erc1155_);
        if (fixedPrice_ != address(0))
            _niftySouqFixedPrice = NiftySouqIFixedPrice(fixedPrice_);
        if (auction_ != address(0))
            _niftySouqAuction = NiftySouqIAuction(auction_);
    }

    //Mint
    function mintNft(MintData memory mintData_)
        public
        returns (
            uint256 tokenId_,
            bool erc1155_,
            address tokenAddress_
        )
    {
        require(mintData_.quantity > 0, "quantity should be grater than 0");

        (
            ContractType contractType,
            bool isERC1155,
            address tokenAddress
        ) = _niftySouqMarketplaceManager.getContractDetails(
                mintData_.tokenAddress,
                mintData_.quantity
            );
        erc1155_ = isERC1155;
        tokenAddress_ = tokenAddress;
        if (isERC1155 && contractType == ContractType.NIFTY_V2) {
            NiftySouqIERC1155V2.MintData
                memory mintData1155_ = NiftySouqIERC1155V2.MintData(
                    mintData_.uri,
                    msg.sender,
                    mintData_.creators,
                    mintData_.royalties,
                    mintData_.investors,
                    mintData_.revenues,
                    mintData_.quantity
                );
            tokenId_ = NiftySouqIERC1155V2(tokenAddress).mint(mintData1155_);
        } else if (
            !isERC1155 &&
            (contractType == ContractType.NIFTY_V2 ||
                contractType == ContractType.COLLECTOR)
        ) {
            NiftySouqIERC721V2.MintData memory mintData721_ = NiftySouqIERC721V2
                .MintData(
                    mintData_.uri,
                    msg.sender,
                    mintData_.creators,
                    mintData_.royalties,
                    mintData_.investors,
                    mintData_.revenues,
                    true
                );
            tokenId_ = NiftySouqIERC721V2(tokenAddress).mint(mintData721_);
            erc1155_ = false;
        }
        emit Mint(
            tokenId_,
            tokenAddress,
            erc1155_,
            msg.sender,
            mintData_.quantity
        );
    }

    //Sell
    function sellNft(
        uint256 tokenId_,
        address tokenAddress_,
        uint256 price_,
        uint256 quantity_,
        bool isBargainable_
    ) public returns (uint256 offerId_) {
        _offerId.increment();
        offerId_ = _offerId.current();
        (
            ContractType contractType,
            bool isERC1155,
            bool isOwner,
            uint256 quantity
        ) = _niftySouqMarketplaceManager.isOwnerOfNFT(
                msg.sender,
                tokenId_,
                tokenAddress_
            );
        require(isOwner, "seller not owner");
        require(quantity >= quantity_, "insufficient token balance");
        _offers[offerId_] = Offer(
            tokenId_,
            OfferType.SALE,
            OfferState.OPEN,
            contractType
        );

        NiftySouqIFixedPrice.SellData memory sellData = NiftySouqIFixedPrice
            .SellData(
                offerId_,
                tokenId_,
                tokenAddress_,
                isERC1155,
                isERC1155 ? quantity_ : 1,
                price_,
                msg.sender,
                isBargainable_
            );
        NiftySouqIFixedPrice(_niftySouqFixedPrice).sell(sellData);
        emit FixedPriceSale(
            offerId_,
            tokenId_,
            tokenAddress_,
            isERC1155,
            msg.sender,
            isERC1155 ? quantity_ : 1,
            price_
        );
    }

    //Mint & Sell
    function mintSellNft(
        MintData calldata mintData_,
        uint256 price_,
        bool isBargainable_
    ) public returns (uint256 tokenId_, uint256 offerId_) {
        (uint256 tokenId, , address tokenAddress) = mintNft(mintData_);
        tokenId_ = tokenId;

        offerId_ = sellNft(
            tokenId,
            tokenAddress,
            price_,
            mintData_.quantity,
            isBargainable_
        );
    }

    function lazyMintSellNft(
        uint256 purchaseQuantity,
        NiftySouqIMarketplaceManager.LazyMintSellData calldata lazyMintSellData_
    ) external payable returns (uint256 offerId_, uint256 tokenId_) {
        require(
            lazyMintSellData_.seller != msg.sender,
            "Nifty1155: seller and buyer is same"
        );

        address signer = _niftySouqMarketplaceManager.verifyFixedPriceLazyMint(
            lazyMintSellData_
        );
        require(
            lazyMintSellData_.seller == signer,
            "Nifty721: signature not verified"
        );

        (offerId_, tokenId_) = _lazyMint(purchaseQuantity, lazyMintSellData_);
    }

    function _lazyMint(
        uint256 purchaseQuantity,
        NiftySouqIMarketplaceManager.LazyMintSellData calldata lazyMintSellData_
    ) private returns (uint256 offerId_, uint256 tokenId_) {
        (
            ContractType contractType,
            bool isERC1155,
            address tokenAddress
        ) = _niftySouqMarketplaceManager.getContractDetails(
                lazyMintSellData_.tokenAddress,
                lazyMintSellData_.quantity
            );

        if (isERC1155 && contractType == ContractType.NIFTY_V2) {
            NiftySouqIERC1155V2.LazyMintData
                memory lazyMintData_ = NiftySouqIERC1155V2.LazyMintData(
                    lazyMintSellData_.uri,
                    lazyMintSellData_.seller,
                    msg.sender,
                    lazyMintSellData_.creators,
                    lazyMintSellData_.royalties,
                    lazyMintSellData_.investors,
                    lazyMintSellData_.revenues,
                    lazyMintSellData_.quantity,
                    purchaseQuantity
                );
            tokenId_ = NiftySouqIERC1155V2(_niftySouqErc1155).lazyMint(
                lazyMintData_
            );
        } else if (
            !isERC1155 &&
            (contractType == ContractType.NIFTY_V2 ||
                contractType == ContractType.COLLECTOR)
        ) {
            MintData memory mintData = MintData(
                tokenAddress,
                lazyMintSellData_.uri,
                lazyMintSellData_.creators,
                lazyMintSellData_.royalties,
                lazyMintSellData_.investors,
                lazyMintSellData_.revenues,
                lazyMintSellData_.quantity
            );

            (
                uint256 tokenId__,
                bool isERC1155__,
                address tokenAddress__
            ) = mintNft(mintData);
            tokenId_ = tokenId__;
            isERC1155 = isERC1155__;
            tokenAddress = tokenAddress__;
        }
        _offerId.increment();
        offerId_ = _offerId.current();

        NiftySouqIFixedPrice.LazyMintData
            memory lazyMintData = NiftySouqIFixedPrice.LazyMintData(
                offerId_,
                tokenId_,
                tokenAddress,
                isERC1155,
                lazyMintSellData_.quantity,
                lazyMintSellData_.minPrice,
                lazyMintSellData_.seller,
                purchaseQuantity,
                msg.sender,
                purchaseQuantity,
                lazyMintSellData_.investors,
                lazyMintSellData_.revenues
            );
        (
            address[] memory recipientAddresses,
            uint256[] memory paymentAmount
        ) = NiftySouqIFixedPrice(_niftySouqFixedPrice).lazyMint(lazyMintData);

        _payout(Payout(address(0), recipientAddresses, paymentAmount));

        _offers[offerId_] = Offer(
            tokenId_,
            OfferType.SALE,
            OfferState.ENDED,
            ContractType.NIFTY_V2
        );
    }

    //Update Price
    function updateSalePrice(uint256 offerId_, uint256 updatedPrice_) public {
        require(offerId_ <= _offerId.current(), "offer id doesnt exist");
        require(
            _offers[offerId_].offerType == OfferType.SALE,
            "offer id is not sale"
        );
        require(
            _offers[offerId_].status == OfferState.OPEN,
            "offer is not active"
        );
        NiftySouqIFixedPrice(_niftySouqFixedPrice).updateSalePrice(
            offerId_,
            updatedPrice_,
            msg.sender
        );
        emit UpdateSalePrice(offerId_, updatedPrice_);
    }

    //Cancel Sale
    function cancelSale(uint256 offerId_) public {
        require(offerId_ <= _offerId.current(), "offer id doesnt exist");
        require(
            _offers[offerId_].offerType == OfferType.SALE,
            "offer id is not sale"
        );
        require(
            _offers[offerId_].status == OfferState.OPEN,
            "offer is not active"
        );
        _offers[offerId_].status = OfferState.CANCELLED;
        emit CancelSale(offerId_);

    }

    // //Make offer for sale
    // function makeOffer(
    //     uint256 offerId_,
    //     uint256 quantity,
    //     uint256 offerPrice
    // ) public {
    //     require(offerId_ <= _offerId.current(), "offer id doesnt exist");
    //     require(
    //         _offers[offerId_].offerType == OfferType.SALE,
    //         "offer id is not sale"
    //     );
    //     require(
    //         _offers[offerId_].status == OfferState.OPEN,
    //         "offer is not active"
    //     );
    //     uint256 offerIdx = NiftySouqIFixedPrice(_niftySouqFixedPrice).makeOffer(
    //         offerId_,
    //         msg.sender,
    //         quantity,
    //         offerPrice
    //     );
    //     emit MakeOffer(offerId_, offerIdx, msg.sender, quantity, offerPrice);
    // }

    // //cancel offer for sale
    // function cancelOffer(uint256 offerId_, uint256 offerIdx_) public {
    //     require(offerId_ <= _offerId.current(), "offer id doesnt exist");
    //     require(
    //         _offers[offerId_].offerType == OfferType.SALE,
    //         "offer id is not sale"
    //     );
    //     (
    //         address[] memory refundAddresses,
    //         uint256[] memory refundAmount
    //     ) = NiftySouqIFixedPrice(_niftySouqFixedPrice).cancelOffer(
    //             offerId_,
    //             msg.sender,
    //             offerIdx_
    //         );

    //     _payout(Payout(address(0), refundAddresses, refundAmount));
    // }

    //Purchase
    function buyNft(uint256 offerId_, uint256 quantity_) public payable {
        require(offerId_ <= _offerId.current(), "offer id doesnt exist");
        require(
            _offers[offerId_].offerType == OfferType.SALE,
            "offer id is not sale"
        );
        require(
            _offers[offerId_].status == OfferState.OPEN,
            "offer is not active"
        );
        NiftySouqIFixedPrice.Payout memory payoutData = NiftySouqIFixedPrice(
            _niftySouqFixedPrice
        ).buyNft(
                NiftySouqIFixedPrice.BuyNFT(
                    offerId_,
                    msg.sender,
                    quantity_,
                    msg.value
                )
            );

        _payout(
            Payout(
                address(0),
                payoutData.refundAddresses,
                payoutData.refundAmount
            )
        );

        _transferNFT(
            payoutData.seller,
            payoutData.buyer,
            payoutData.tokenId,
            payoutData.tokenAddress,
            payoutData.quantity
        );

        if (payoutData.soldout) {
            _offers[offerId_].status = OfferState.ENDED;
            emit Purchase(offerId_, msg.sender, address(0), quantity_, true);
        } else {
            emit Purchase(offerId_, msg.sender, address(0), quantity_, false);
        }
    }

    // // Accept Offer
    // function acceptOffer(uint256 offerId_, uint256 offerIdx_) public payable {
    //     require(offerId_ <= _offerId.current(), "offer id doesnt exist");
    //     require(
    //         _offers[offerId_].offerType == OfferType.SALE,
    //         "offer id is not sale"
    //     );
    //     require(
    //         _offers[offerId_].status == OfferState.OPEN,
    //         "offer is not active"
    //     );
    //     NiftySouqIFixedPrice.Payout memory payoutData = NiftySouqIFixedPrice(
    //         _niftySouqFixedPrice
    //     ).acceptOffer(offerId_, msg.sender, offerIdx_);

    //     _payout(
    //         Payout(
    //             address(0),
    //             payoutData.refundAddresses,
    //             payoutData.refundAmount
    //         )
    //     );
    //     _transferNFT(
    //         payoutData.seller,
    //         payoutData.buyer,
    //         payoutData.tokenId,
    //         payoutData.tokenAddress,
    //         payoutData.quantity
    //     );

    //     if (payoutData.soldout) {
    //         _offers[offerId_].status = OfferState.ENDED;
    //         emit AcceptOffer(
    //             offerId_,
    //             offerIdx_,
    //             payoutData.buyer,
    //             address(0),
    //             payoutData.quantity,
    //             true
    //         );
    //     } else {
    //         emit AcceptOffer(
    //             offerId_,
    //             offerIdx_,
    //             payoutData.buyer,
    //             address(0),
    //             payoutData.quantity,
    //             false
    //         );
    //     }
    // }

    //Create Auction
    function createAuction(CreateAuctionData memory createAuctionData_)
        public
        returns (uint256 offerId_)
    {
        _offerId.increment();
        offerId_ = _offerId.current();
        (
            ContractType contractType,
            bool isERC1155,
            bool isOwner,

        ) = _niftySouqMarketplaceManager.isOwnerOfNFT(
                msg.sender,
                createAuctionData_.tokenId,
                createAuctionData_.tokenContract
            );
        require(isOwner, "seller not owner");
        require(!isERC1155, "cannot auction erc1155 token");

        _offers[offerId_] = Offer(
            createAuctionData_.tokenId,
            OfferType.AUCTION,
            OfferState.OPEN,
            contractType
        );

        NiftySouqIAuction.CreateAuction memory auctionData = NiftySouqIAuction
            .CreateAuction(
                offerId_,
                createAuctionData_.tokenId,
                createAuctionData_.tokenContract,
                block.timestamp,
                createAuctionData_.duration,
                msg.sender,
                createAuctionData_.startBidPrice,
                createAuctionData_.reservePrice
            );
        NiftySouqIAuction(_niftySouqAuction).createAuction(auctionData);
        emit CreateAuction(
            offerId_,
            createAuctionData_.tokenId,
            createAuctionData_.tokenContract,
            msg.sender,
            block.timestamp,
            createAuctionData_.duration,
            createAuctionData_.startBidPrice,
            createAuctionData_.reservePrice
        );
    }

    //Mint and Auction
    function mintCreateAuctionNft(
        MintAndCreateAuctionData calldata mintNCreateAuction_
    ) public returns (uint256 offerId_, uint256 tokenId_) {
        (uint256 tokenId, , address tokenAddress) = mintNft(
            MintData(
                mintNCreateAuction_.tokenAddress,
                mintNCreateAuction_.uri,
                mintNCreateAuction_.creators,
                mintNCreateAuction_.royalties,
                mintNCreateAuction_.investors,
                mintNCreateAuction_.revenues,
                1
            )
        );

        offerId_ = createAuction(
            CreateAuctionData(
                tokenId,
                tokenAddress,
                mintNCreateAuction_.duration,
                mintNCreateAuction_.startBidPrice,
                mintNCreateAuction_.reservePrice
            )
        );
        tokenId_ = tokenId;
    }

    //End Auction
    function endAuction(uint256 offerId_, uint256 bidIdx_) public {
        require(offerId_ <= _offerId.current(), "offer id doesnt exist");
        require(
            _offers[offerId_].offerType == OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            _offers[offerId_].status == OfferState.OPEN,
            "offer is not active"
        );
        (
            uint256 bidAmount,
            address[] memory refundAddresses,
            uint256[] memory refundAmount
        ) = NiftySouqIAuction(_niftySouqAuction).endAuction(
                offerId_,
                msg.sender,
                bidIdx_
            );

        NiftySouqIAuction.Auction memory auctionDetails = NiftySouqIAuction(
            _niftySouqAuction
        ).getAuctionDetails(offerId_);
        _transferNFT(
            auctionDetails.seller,
            auctionDetails.bids[bidIdx_].bidder,
            auctionDetails.tokenId,
            auctionDetails.tokenContract,
            1
        );
        NiftySouqIMarketplaceManager.CryptoTokens
            memory wethDetails = _niftySouqMarketplaceManager.cryptoTokenList(
                "weth"
            );
        _payout(
            Payout(wethDetails.tokenAddress, refundAddresses, refundAmount)
        );
        emit EndAuction(offerId_, bidIdx_, msg.sender, address(0), bidAmount);
    }

    //End Auction with highest bid
    function endAuctionHighestBid(uint256 offerId_) public {
        require(offerId_ <= _offerId.current(), "offer id doesnt exist");
        require(
            _offers[offerId_].offerType == OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            _offers[offerId_].status == OfferState.OPEN,
            "offer is not active"
        );
        (
            uint256 bidIdx,
            uint256 bidAmount,
            address[] memory refundAddresses,
            uint256[] memory refundAmount
        ) = NiftySouqIAuction(_niftySouqAuction).endAuctionWithHighestBid(
                offerId_,
                msg.sender
            );

        NiftySouqIAuction.Auction memory auctionDetails = NiftySouqIAuction(
            _niftySouqAuction
        ).getAuctionDetails(offerId_);
        _transferNFT(
            auctionDetails.seller,
            auctionDetails.bids[bidIdx].bidder,
            auctionDetails.tokenId,
            auctionDetails.tokenContract,
            1
        );
        NiftySouqIMarketplaceManager.CryptoTokens
            memory wethDetails = _niftySouqMarketplaceManager.cryptoTokenList(
                "weth"
            );

        _payout(
            Payout(wethDetails.tokenAddress, refundAddresses, refundAmount)
        );
        emit EndAuction(offerId_, bidIdx, msg.sender, address(0), bidAmount);
    }

    //Cancel Auction
    function cancelAuction(uint256 offerId_) public {
        require(offerId_ <= _offerId.current(), "offer id doesnt exist");
        require(
            _offers[offerId_].offerType == OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            _offers[offerId_].status == OfferState.OPEN,
            "offer is not active"
        );
        (
            address[] memory refundAddresses,
            uint256[] memory refundAmount
        ) = NiftySouqIAuction(_niftySouqAuction).cancelAuction(offerId_);
        NiftySouqIMarketplaceManager.CryptoTokens
            memory wethDetails = _niftySouqMarketplaceManager.cryptoTokenList(
                "weth"
            );

        _payout(
            Payout(wethDetails.tokenAddress, refundAddresses, refundAmount)
        );
        emit CancelAuction(offerId_);
    }

    //place bid function for lazy mint token
    function lazyMintAuctionNPlaceBid(
        NiftySouqIMarketplaceManager.LazyMintAuctionData
            calldata lazyMintAuctionData_,
        uint256 bidPrice
    )
        public
        returns (
            uint256 offerId_,
            uint256 tokenId_,
            uint256 bidIdx_
        )
    {
        address signer = _niftySouqMarketplaceManager.verifyAuctionLazyMint(
            lazyMintAuctionData_
        );
        require(
            lazyMintAuctionData_.seller == signer,
            "Nifty721: signature not verified"
        );
        address tokenAddress;
        if (lazyMintAuctionData_.tokenAddress == address(0))
            tokenAddress = address(_niftySouqErc721);
        else tokenAddress = lazyMintAuctionData_.tokenAddress;
        (
            ContractType contractType,
            bool isERC1155,
            bool isOwner,

        ) = _niftySouqMarketplaceManager.isOwnerOfNFT(
                msg.sender,
                tokenId_,
                tokenAddress
            );
        require(isOwner, "seller not owner");
        require(!isERC1155, "cannot auction erc1155 token");
        require(
            (contractType == ContractType.NIFTY_V2 ||
                contractType == ContractType.COLLECTOR) && !isERC1155,
            "Not niftysouq contract"
        );
        //mint nft
        NiftySouqIERC721V2.MintData memory mintData721_ = NiftySouqIERC721V2
            .MintData(
                lazyMintAuctionData_.uri,
                lazyMintAuctionData_.seller,
                lazyMintAuctionData_.creators,
                lazyMintAuctionData_.royalties,
                lazyMintAuctionData_.investors,
                lazyMintAuctionData_.revenues,
                false
            );
        tokenId_ = NiftySouqIERC721V2(tokenAddress).mint(mintData721_);

        //create auction
        _offerId.increment();
        offerId_ = _offerId.current();
        _offers[offerId_] = Offer(
            tokenId_,
            OfferType.AUCTION,
            OfferState.OPEN,
            contractType
        );

        NiftySouqIAuction.CreateAuction memory auctionData = NiftySouqIAuction
            .CreateAuction(
                offerId_,
                tokenId_,
                address(_niftySouqErc721),
                lazyMintAuctionData_.startTime,
                lazyMintAuctionData_.duration,
                lazyMintAuctionData_.seller,
                lazyMintAuctionData_.startBidPrice,
                lazyMintAuctionData_.reservePrice
            );
        NiftySouqIAuction(_niftySouqAuction).createAuction(auctionData);

        //place bid
        bidIdx_ = placeBid(offerId_, bidPrice);
    }

    //Place Bid
    function placeBid(uint256 offerId, uint256 bidPrice)
        public
        returns (uint256 bidIdx_)
    {
        require(offerId <= _offerId.current(), "offer id doesnt exist");
        require(
            _offers[offerId].offerType == OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            _offers[offerId].status == OfferState.OPEN,
            "offer is not active"
        );
        NiftySouqIMarketplaceManager.CryptoTokens
            memory wethDetails = _niftySouqMarketplaceManager.cryptoTokenList(
                "weth"
            );

        IERC20(wethDetails.tokenAddress).transferFrom(
            msg.sender,
            address(this),
            bidPrice
        );

        bidIdx_ = NiftySouqIAuction(_niftySouqAuction).placeBid(
            offerId,
            msg.sender,
            bidPrice
        );
        emit PlaceBid(offerId, bidIdx_, msg.sender, bidPrice);
    }

    //Place Higher Bid
    function placeHigherBid(
        uint256 offerId,
        uint256 bidIdx,
        uint256 bidPrice
    ) public {
        require(offerId <= _offerId.current(), "offer id doesnt exist");
        require(
            _offers[offerId].offerType == OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            _offers[offerId].status == OfferState.OPEN,
            "offer is not active"
        );
        NiftySouqIMarketplaceManager.CryptoTokens
            memory wethDetails = _niftySouqMarketplaceManager.cryptoTokenList(
                "weth"
            );

        IERC20(wethDetails.tokenAddress).transferFrom(
            msg.sender,
            address(this),
            bidPrice
        );

        uint256 currentBidAmount = NiftySouqIAuction(_niftySouqAuction)
            .placeHigherBid(offerId, msg.sender, bidIdx, bidPrice);
        emit PlaceHigherBid(offerId, bidIdx, msg.sender, currentBidAmount);
    }

    //Cancel Bid
    function cancelBid(uint256 offerId, uint256 bidIdx) public {
        require(offerId <= _offerId.current(), "offer id doesnt exist");
        require(
            _offers[offerId].offerType == OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            _offers[offerId].status == OfferState.OPEN,
            "offer is not active"
        );
        (
            address[] memory refundAddresses,
            uint256[] memory refundAmount
        ) = NiftySouqIAuction(_niftySouqAuction).cancelBid(
                offerId,
                msg.sender,
                bidIdx
            );
        NiftySouqIMarketplaceManager.CryptoTokens
            memory wethDetails = _niftySouqMarketplaceManager.cryptoTokenList(
                "weth"
            );

        _payout(
            Payout(wethDetails.tokenAddress, refundAddresses, refundAmount)
        );
        emit CancelBid(offerId, bidIdx);
    }

    //get offer details
    function getOfferStatus(uint256 offerId_)
        public
        view
        returns (Offer memory offerDetails_)
    {
        offerDetails_ = _offers[offerId_];
    }

    //get offer details
    function getFixedPriceStatus(uint256 offerId_)
        public
        view
        returns (NiftySouqIFixedPrice.Sale memory saleDetails_)
    {
        saleDetails_ = NiftySouqIFixedPrice(_niftySouqFixedPrice)
            .getSaleDetails(offerId_);
    }

    //get offer details
    function getAuctionStatus(uint256 offerId_)
        public
        view
        returns (NiftySouqIAuction.Auction memory auctionDetails_)
    {
        auctionDetails_ = NiftySouqIAuction(_niftySouqAuction)
            .getAuctionDetails(offerId_);
    }

    function _payout(Payout memory payoutData_) internal {
        for (uint256 i = 0; i < payoutData_.refundAddresses.length; i++) {
            if (payoutData_.refundAddresses[i] != address(0)) {
                if (address(0) == payoutData_.currency) {
                    payable(payoutData_.refundAddresses[i]).transfer(
                        payoutData_.refundAmounts[i]
                    );
                } else {
                    IERC20(payoutData_.currency).transfer(
                        payoutData_.refundAddresses[i],
                        payoutData_.refundAmounts[i]
                    );
                }
                emit PayoutTransfer(
                    payoutData_.refundAddresses[i],
                    payoutData_.refundAmounts[i],
                    payoutData_.currency
                );
            }
        }
    }

    function _transferNFT(
        address from_,
        address to_,
        uint256 tokenId_,
        address tokenAddress_,
        uint256 quantity_
    ) internal {
        (
            ContractType contractType,
            bool isERC1155,
            bool isOwner,
            uint256 quantity
        ) = _niftySouqMarketplaceManager.isOwnerOfNFT(
                from_,
                tokenId_,
                tokenAddress_
            );
        require(isOwner, "seller not owner");
        require(quantity >= quantity_, "insufficient token balance");
        if (
            (contractType == ContractType.NIFTY_V2 ||
                contractType == ContractType.COLLECTOR) && !isERC1155
        ) {
            NiftySouqIERC721V2(tokenAddress_).transferNft(from_, to_, tokenId_);
        } else if (contractType == ContractType.NIFTY_V2 && isERC1155) {
            NiftySouqIERC1155V2(tokenAddress_).transferNft(
                from_,
                to_,
                tokenId_,
                quantity_
            );
        } else if (contractType == ContractType.EXTERNAL && !isERC1155) {
            NiftySouqIERC721V2(tokenAddress_).transferFrom(
                from_,
                to_,
                tokenId_
            );
        } else if (contractType == ContractType.EXTERNAL && isERC1155) {
            NiftySouqIERC1155V2(tokenAddress_).safeTransferFrom(
                from_,
                to_,
                tokenId_,
                quantity_,
                ""
            );
        }
    }
}