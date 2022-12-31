// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IRoyaltyManager.sol";
import "./interfaces/IAuctionManager.sol";
import "./lib/CurrencyWhiteList.sol";
import "./lib/NftBlackList.sol";
import "./lib/MarketGeneralBase.sol";

contract VCGMarketGeneral is
    MarketGeneralBase,
    CurrencyWhitelist,
    NftBlackList,
    ReentrancyGuard,
    Pausable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public txFee;
    uint256 public creatorPortion = 7000; // creator portion 70% for royalty
    IRoyaltyManager public royaltyManager;
    IAuctionManager public auctionManager;

    event newOffer(Offer, address[]);
    event acceptedOffer(Offer, address);
    event canceledOffer(Offer);

    mapping(uint => mapping(address => bool)) public whiteListedTransact; // nonce => wallet address => can buy/no
    mapping(uint => bool) public isNeedWhiteList; // nonce => use whitelist

    constructor() {
        txFee = 250; // 2.5%
    }

    // withdraw function
    function withdrawBNB() public onlyOwner {
        require(address(this).balance > 0, "does not have any balance");
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken(address _tokenAddress, uint256 _amount)
        public
        onlyOwner
    {
        IERC20(_tokenAddress).transfer(msg.sender, _amount);
    }

    // setup contract
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setTxFee(uint256 _fee) external onlyOwner {
        require(
            _fee >= 0 && _fee <= 10000,
            "VCGMarketGeneral: must between base & max fee"
        );
        require(_fee != txFee, "VCGMarketGeneral: cannot set same fee");
        txFee = _fee;
    }

    function setRoyaltyManager(address _royaltyManager) external onlyOwner {
        require(
            _royaltyManager != address(0),
            "VCGMarketGeneral: cannot setup address 0"
        );
        require(
            IRoyaltyManager(_royaltyManager) != royaltyManager,
            "VCGMarketGeneral: cannot setup same address"
        );

        royaltyManager = IRoyaltyManager(_royaltyManager);
    }

    function setAuctionManager(address _auctionManager) external onlyOwner {
        require(
            _auctionManager != address(0),
            "VCGMarketGeneral: cannot setup address 0"
        );
        require(
            IAuctionManager(_auctionManager) != auctionManager,
            "VCGMarketGeneral: cannot setup same address"
        );

        auctionManager = IAuctionManager(_auctionManager);
    }

    function setCreatorPortion(uint _creatorPortion) external onlyOwner {
        require(
            _creatorPortion >= 0 && _creatorPortion <= 10000, 
            "max portion exceed"
        );
        creatorPortion = _creatorPortion;
    }

    // main offer
    function offer(
        Offer memory _offer,
        address[] calldata currencies,
        bool buyOut,
        address[] calldata whiteListedAddress
    )
        public
        nonReentrant
        notContract
        whenNotPaused
        _validCurrency(currencies)
        _nftNotBlackListed(_offer.collection)
        _checkLastOffer(_offer.nonce)
    {
        require(
            offers[_offer.nonce].status != OfferStatus.Cancelled &&
                offers[_offer.nonce].status != OfferStatus.Accepted,
            "VCGMarketGeneral: offer already cancel/accepted"
        );

        if (_offer.side == Side.Sell) {
            _offerSale(_offer, currencies, buyOut);
            if (whiteListedAddress.length > 0) {
                for (uint i = 0; i < whiteListedAddress.length; i++) {
                    whiteListedTransact[_offer.nonce][
                        whiteListedAddress[i]
                    ] = true;
                }
                isNeedWhiteList[_offer.nonce] = true;
            }
        } else if (_offer.side == Side.Bid) {
            _offerBid(_offer, currencies[0]);
        }

        emit newOffer(offers[_offer.nonce], currencies);
    }

    // main accept
    function accept(
        uint256 nonce,
        uint256 nftAmount,
        address currencyAddress,
        uint256 currencyAmount
    ) public nonReentrant notContract whenNotPaused _offerValid(nonce) {
        Offer memory _offer = offers[nonce];

        if (_offer.side == Side.Sell) {
            require(
                offerCurrencies[nonce][currencyAddress],
                "VCGMarketGeneral: Currency Not Supported"
            );
            if (isNeedWhiteList[nonce]) {
                require(
                    whiteListedTransact[nonce][msg.sender],
                    "not whitelisted"
                );
            }
            if (_offer.strategy == OfferStrategy.FixedPrice) {
                _fixedPriceHandler(_offer, currencyAddress, nftAmount);
            } else if (_offer.strategy == OfferStrategy.Auction) {
                _auctionHandler(_offer, currencyAddress, currencyAmount);
            }
        } else if (_offer.side == Side.Bid) {
            _acceptBid(_offer, nftAmount);
        }

        emit acceptedOffer(offers[_offer.nonce], msg.sender);
    }

    // main cancel
    function cancel(uint256 nonce)
        public
        notContract
        nonReentrant
        _offerOwner(nonce)
        whenNotPaused
    {
        require(offers[nonce].status == OfferStatus.Open, "offer not active");
        if (offers[nonce].side == Side.Sell) {
            if (offers[nonce].strategy == OfferStrategy.Auction) {
                require(
                    block.timestamp < offers[nonce].startTime,
                    "VCGMarketGeneral: Auction already start"
                );
            }
            _cancelSell(offers[nonce]);
        } else if (offers[nonce].side == Side.Bid) {
            _cancelBid(offers[nonce]);
        }

        emit canceledOffer(offers[nonce]);
    }

    // create offer sale
    function _offerSale(
        Offer memory _offer,
        address[] memory currencies,
        bool buyOut
    ) internal {
        if (_offer.strategy == OfferStrategy.Auction) {
            auctionInfos[_offer.nonce].auctionCurrency = currencies[0];
            auctionInfos[_offer.nonce].buyOut = buyOut;
        }

        if (_offer.collectionType == CollectionType.ERC721) {
            IERC721 nft = IERC721(_offer.collection);
            _validateER721(msg.sender, nft, _offer.tokenId);
            _offer.status = OfferStatus.Open;
            _offer.maker = msg.sender;
            offers[_offer.nonce] = _offer;
        }

        if (_offer.collectionType == CollectionType.ERC1155) {
            IERC1155 nft = IERC1155(_offer.collection);
            _validateERC1155(msg.sender, nft, _offer.tokenId, _offer.amount);
            _offer.status = OfferStatus.Open;
            _offer.maker = msg.sender;
            offers[_offer.nonce] = _offer;
        }

        for (uint256 i = 0; i < currencies.length; i++) {
            offerCurrencies[_offer.nonce][currencies[i]] = true;
        }
    }

    // create offer bid
    function _offerBid(Offer memory _offer, address currency) internal {
        _offer.status = OfferStatus.Open;
        uint256 previousBid = offers[_offer.nonce].amount.mul(
            offers[_offer.nonce].price
        );
        uint256 currentBid = _offer.amount.mul(_offer.price);
        offers[_offer.nonce] = _offer;
        bidInfos[_offer.nonce].bidCurrency = currency;

        if (currentBid > previousBid) {
            _transferERC(
                msg.sender,
                address(this),
                currentBid - previousBid,
                IERC20(currency)
            );
        } else if (previousBid > currentBid) {
            IERC20(currency).transfer(msg.sender, previousBid - currentBid);
        }
    }

    // cancel handler
    function _cancelSell(Offer memory _offer) internal {
        _offer.status = OfferStatus.Cancelled;
        offers[_offer.nonce] = _offer;
    }

    function _cancelBid(Offer memory _offer) internal {
        _offer.status = OfferStatus.Cancelled;
        offers[_offer.nonce] = _offer;

        IERC20(bidInfos[_offer.nonce].bidCurrency).transfer(
            msg.sender,
            _offer.amount.mul(_offer.price)
        );

        delete bidInfos[_offer.nonce];
    }

    // accept handler
    function _fixedPriceHandler(
        Offer memory _offer,
        address currencyAddress,
        uint256 nftAmount
    )
        internal
        _checkCurrencyValidity(currencyAddress, _offer.price.mul(nftAmount))
    {
        require(
            _offer.amount.sub(nftAmount) >= 0,
            "VCGMarketGeneral: more than nft amount"
        );
        uint256 royaltyFee = royaltyManager.addRoyalty(
            _offer.collection,
            _offer.price.mul(nftAmount),
            currencyAddress,
            _offer.tokenId
        );

        TransferHandler memory args = TransferHandler(
            _offer,
            _offer.maker,
            msg.sender,
            calculateFee(_offer.price.mul(nftAmount), royaltyFee),
            calculateSellerPayment(
                _offer.price.mul(nftAmount),
                calculateFee(_offer.price.mul(nftAmount), royaltyFee)
            ),
            nftAmount,
            currencyAddress
        );
        _transferHandler(args);
        _acceptOfferSell(_offer, nftAmount);
    }

    function _auctionHandler(
        Offer memory _offer,
        address currencyAddress,
        uint256 currencyAmount
    ) internal _checkCurrencyValidity(currencyAddress, currencyAmount) {
        if (
            auctionInfos[_offer.nonce].buyOut &&
            currencyAmount >= _offer.amount.mul(_offer.price)
        ) {
            uint256 royaltyFee = royaltyManager.addRoyalty(
                _offer.collection,
                _offer.amount.mul(_offer.price),
                currencyAddress,
                _offer.tokenId
            );
            uint256 makerPercentageAmount = calculateSellerPayment(
                _offer.amount.mul(_offer.price),
                calculateFee(_offer.amount.mul(_offer.price), royaltyFee)
            );

            TransferHandler memory args = TransferHandler(
                _offer,
                _offer.maker,
                msg.sender,
                calculateFee(_offer.amount.mul(_offer.price), royaltyFee),
                makerPercentageAmount,
                _offer.amount,
                currencyAddress
            );
            _transferHandler(args);
            _acceptOfferSell(_offer, _offer.amount);
            return;
        }

        auctionManager.bid(_offer.nonce, currencyAmount, msg.sender);
        _transferERC(
            msg.sender,
            address(this),
            currencyAmount,
            IERC20(currencyAddress)
        );
    }

    function _acceptOfferSell(Offer memory _offer, uint256 nftAmount) internal {
        _offer.amount = _offer.amount.sub(nftAmount);
        if (_offer.amount == 0) {
            _offer.status = OfferStatus.Accepted;
        }
        offers[_offer.nonce] = _offer;
    }

    function _acceptBid(Offer memory _offer, uint256 nftAmount) internal {
        require(
            _offer.amount >= nftAmount,
            "VCGMarketGeneral: NFT stock is not match"
        );
        uint256 royaltyFee = royaltyManager.addRoyalty(
            _offer.collection,
            _offer.price.mul(nftAmount),
            bidInfos[_offer.nonce].bidCurrency,
            _offer.tokenId
        );
        uint256 sellerPercentageAmount = calculateSellerPayment(
            _offer.price.mul(nftAmount),
            calculateFee(_offer.price.mul(nftAmount), royaltyFee)
        );

        _transferNFT(_offer, msg.sender, _offer.maker, nftAmount);

        IERC20(bidInfos[_offer.nonce].bidCurrency).transfer(
            msg.sender,
            sellerPercentageAmount
        );

        _acceptOfferBuy(_offer, nftAmount);
    }

    function _acceptOfferBuy(Offer memory _offer, uint256 nftAmount) internal {
        _offer.amount = _offer.amount.sub(nftAmount);
        if (_offer.amount == 0) {
            _offer.status = OfferStatus.Accepted;
        }
        offers[_offer.nonce] = _offer;
    }

    // auction withdrawal
    function withdrawLose(uint256 nonce) public {
        (address highestBidder, ) = auctionManager.getHighestBidder(nonce);
        require(
            highestBidder != msg.sender,
            "VCGMarketGeneral: you are highest bidder"
        );
        uint256 bidAmount = auctionManager.getWithdrawAmount(nonce, msg.sender);

        IERC20(auctionInfos[nonce].auctionCurrency).transfer(
            msg.sender,
            bidAmount
        );
    }

    function claimAuctionWinner(uint256 nonce) public {
        require(
            block.timestamp > offers[nonce].endTime,
            "VCGMarketGeneral: Auction still live"
        );
        require(
            offers[nonce].status == OfferStatus.Open,
            "VCGMarketGeneral: already claimed"
        );
        (address highestBidder, uint256 highestBid) = auctionManager
            .getHighestBidder(nonce);
        require(
            msg.sender == highestBidder,
            "VCGMarketGeneral: not auction winner"
        );

        uint256 royaltyFee = royaltyManager.addRoyalty(
            offers[nonce].collection,
            highestBid,
            auctionInfos[nonce].auctionCurrency,
            offers[nonce].tokenId
        );
        uint256 makerPercentageAmount = highestBid.sub(
            highestBid.div(10000).mul(txFee).add(royaltyFee)
        );

        _transferNFT(
            offers[nonce],
            offers[nonce].maker,
            msg.sender,
            offers[nonce].amount
        );
        IERC20(auctionInfos[nonce].auctionCurrency).transfer(
            offers[nonce].maker,
            makerPercentageAmount
        );

        _acceptOfferSell(offers[nonce], offers[nonce].amount);
    }

    function claimSellerAuction(uint256 nonce) public {
        require(
            block.timestamp > offers[nonce].endTime,
            "VCGMarketGeneral: Auction still live"
        );
        require(
            msg.sender == offers[nonce].maker,
            "VCGMarketGeneral: not offer maker"
        );
        require(
            offers[nonce].status == OfferStatus.Open,
            "VCGMarketGeneral: already claimed"
        );

        (address highestBidder, uint256 highestBid) = auctionManager
            .getHighestBidder(nonce);

        uint256 royaltyFee = royaltyManager.addRoyalty(
            offers[nonce].collection,
            highestBid,
            auctionInfos[nonce].auctionCurrency,
            offers[nonce].tokenId
        );
        uint256 makerPercentageAmount = highestBid.sub(
            highestBid.div(10000).mul(txFee).add(royaltyFee)
        );

        _transferNFT(
            offers[nonce],
            msg.sender,
            highestBidder,
            offers[nonce].amount
        );

        _transferERC(
            address(this),
            msg.sender,
            makerPercentageAmount,
            IERC20(auctionInfos[nonce].auctionCurrency)
        );
        _acceptOfferSell(offers[nonce], offers[nonce].amount);
    }

    // royalty claim
    function claimRoyalty(
        address collection,
        address _token,
        uint _tokenId
    ) external {
        if (royaltyManager.checkVCGNFT(collection)) {
            IRoyaltyManager.CollectionInfo
                memory mainCollectionInfo = royaltyManager
                    .getMainCollectionRoyaltyInfo(collection, _tokenId);
            require(
                mainCollectionInfo.collectionTaker == msg.sender,
                "VCGMarketGeneral: not colletion taker"
            );

            uint256 withdrawAmount = royaltyManager.withdrawRoyalty(
                collection,
                _token,
                _tokenId
            );

            IERC20(_token).transfer(
                msg.sender,
                withdrawAmount.mul(creatorPortion).div(10000)
            ); // creator portion is divide with marketplace contract
        } else {
            IRoyaltyManager.CollectionInfo
                memory collectionInfo = royaltyManager.getCollectionRoyaltyInfo(
                    collection
                );
            require(
                collectionInfo.collectionTaker == msg.sender,
                "VCGMarketGeneral: not colletion taker"
            );

            uint256 withdrawAmount = royaltyManager.withdrawRoyalty(
                collection,
                _token,
                _tokenId
            );

            IERC20(_token).transfer(msg.sender, withdrawAmount);
        }
    }

    // helper
    function _transferERC(
        address from,
        address to,
        uint256 amount,
        IERC20 _token
    ) internal {
        require(
            amount > 0 && to != address(0),
            "VCGMarketGeneral: wrong amount or dest on transfer"
        );
        _token.safeTransferFrom(from, to, amount);
    }

    function _transferNFT(
        Offer memory _offer,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (_offer.collectionType == CollectionType.ERC1155) {
            _validateERC1155(
                from,
                IERC1155(_offer.collection),
                _offer.tokenId,
                amount
            );
            IERC1155(_offer.collection).safeTransferFrom(
                from,
                to,
                _offer.tokenId,
                amount,
                ""
            );
        }

        if (_offer.collectionType == CollectionType.ERC721) {
            _validateER721(from, IERC721(_offer.collection), _offer.tokenId);
            IERC721(_offer.collection).safeTransferFrom(
                from,
                to,
                _offer.tokenId
            );
        }
    }

    function _validateER721(
        address owner,
        IERC721 nft,
        uint256 tokenId
    ) internal view {
        require(
            nft.ownerOf(tokenId) == owner,
            "VCGMarketGeneral: ERC721 not owner"
        );
        require(
            nft.getApproved(tokenId) == address(this) ||
                nft.isApprovedForAll(owner, address(this)),
            "VCGMarketGeneral: ERC721 not approved"
        );
    }

    function _validateERC1155(
        address owner,
        IERC1155 nft,
        uint256 tokenId,
        uint256 nftAmount
    ) internal view {
        require(
            nft.balanceOf(owner, tokenId) >= nftAmount,
            "VCGMarketGeneral: ERC1155 not enough balance"
        );
        require(
            nft.isApprovedForAll(owner, address(this)),
            "VCGMarketGeneral: ERC1155 not approved"
        );
    }

    function _transferHandler(TransferHandler memory args) internal {
        _transferNFT(args.offer, args.seller, args.buyer, args.nftAmount);

        _transferERC(
            args.buyer,
            address(this),
            args.paymentFee,
            IERC20(args.currencyAddress)
        );

        _transferERC(
            args.buyer,
            args.seller,
            args.payment,
            IERC20(args.currencyAddress)
        );
    }

    function calculateFee(uint256 payment, uint256 royalty)
        internal
        view
        returns (uint256)
    {
        return (payment.div(10000).mul(txFee)).add(royalty);
    }

    function calculateSellerPayment(uint256 payment, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return payment.sub(fee);
    }
}