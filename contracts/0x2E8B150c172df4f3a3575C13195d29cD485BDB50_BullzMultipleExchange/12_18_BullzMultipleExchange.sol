// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

import "../loyalties/interfaces/ILoyalty.sol";
import "./FeeManager.sol";

import "./interfaces/IBullzMultipleExchange.sol";

import "./libraries/BullzLibrary.sol";
import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BullzMultipleExchange is
    IBullzMultipleExchange,
    FeeManager,
    ERC1155Holder
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _offerIdCounter;
    //ERC1155
    mapping(bytes32 => Offer) public offers;
    // For auctions bid by bider, collection and assetId
    mapping(bytes32 => mapping(address => Bid)) public bidforAuctions;

    modifier onlyOfferOwner(bytes32 offerId) {
        require(_msgSender() == offers[offerId].seller);
        _;
    }

    constructor() {}

    function addOffer(CreateOffer calldata newOffer) external override {
        (bool success, ) = address(newOffer._collection).call(
            abi.encodeWithSignature("isLoyalty()")
        );
        if (success) {
            require(
                ILoyalty(newOffer._collection).isResaleAllowed(
                    newOffer._assetId,
                    _msgSender()
                ),
                "Marketplace: Resale not allowed"
            );
        }
        _addOffer(newOffer);
    }

    function _addOffer(CreateOffer memory newOffer) internal {
        require(
            newOffer._collection != address(0),
            "Marketplace: Collection address is not valid"
        );
        require(
            newOffer._token != address(0),
            "Marketplace: Token address is not valid"
        );
        require(
            newOffer._price > 0,
            "Marketplace: Price must be greater than zero"
        );
        require(
            newOffer._amount > 0,
            "Marketplace: Amount must be greater than zero"
        );
        require(
            newOffer._expiresAt > block.timestamp,
            "Marketplace: invalid expire time"
        );

        // get NFT asset from seller
        IERC1155 multipleNFTCollection = IERC1155(newOffer._collection);
        require(
            multipleNFTCollection.balanceOf(_msgSender(), newOffer._assetId) >=
                newOffer._amount,
            "Insufficient token balance"
        );
        require(
            multipleNFTCollection.isApprovedForAll(_msgSender(), address(this)),
            "Contract not approved"
        );

        _offerIdCounter.increment();
        uint256 newOfferId = _offerIdCounter.current();
        bytes32 offerId = keccak256(
            abi.encodePacked(
                newOfferId,
                _msgSender(),
                newOffer._collection,
                newOffer._assetId
            )
        );

        offers[offerId] = Offer(
            _msgSender(),
            newOffer._collection,
            newOffer._assetId,
            newOffer._token,
            newOffer._price,
            newOffer._amount,
            newOffer._isForSell,
            newOffer._isForAuction,
            newOffer._expiresAt,
            newOffer._shareIndex,
            true //offer exists
        );
        IERC1155(newOffer._collection).safeTransferFrom(
            _msgSender(),
            address(this),
            newOffer._assetId,
            newOffer._amount,
            ""
        );
        emit Listed(
            offerId,
            _msgSender(),
            newOffer._collection,
            newOffer._assetId,
            newOffer._price,
            newOffer._amount,
            newOffer.eventIdListed
        );
    }

    function setOfferPrice(
        bytes32 offerID,
        uint256 price,
        uint256 eventIdSetOfferPrice
    ) external override onlyOfferOwner(offerID) {
        Offer storage offer = _getOwnerOffer(offerID);
        offer.price = price;
        emit SetOfferPrice(offerID, price, eventIdSetOfferPrice);
    }

    function setForSell(
        bytes32 offerID,
        bool isForSell,
        uint256 eventIdSetForSell
    ) external override onlyOfferOwner(offerID) {
        Offer storage offer = _getOwnerOffer(offerID);
        offer.isForSell = isForSell;
        emit SetForSell(offerID, isForSell, eventIdSetForSell);
    }

    function setForAuction(
        bytes32 offerID,
        bool isForAuction,
        uint256 eventIdSetForAuction
    ) external override onlyOfferOwner(offerID) {
        Offer storage offer = _getOwnerOffer(offerID);
        offer.isForAuction = isForAuction;
        emit SetForAuction(offerID, isForAuction, eventIdSetForAuction);
    }

    function setExpiresAt(
        bytes32 offerID,
        uint256 expiresAt,
        uint256 eventIdSetExpireAt
    ) external override onlyOfferOwner(offerID) {
        Offer storage offer = _getOwnerOffer(offerID);
        offer.expiresAt = expiresAt;
        emit SetExpireAt(offerID, expiresAt, eventIdSetExpireAt);
    }

    function cancelOffer(bytes32 offerID, uint256 eventIdCancelOffer)
        external
        override
        onlyOfferOwner(offerID)
    {
        Offer memory offer = _getOwnerOffer(offerID);
        require(offer.expiresAt < block.timestamp, "Offer should be expired");
        delete offers[offerID];
        IERC1155(offer.collection).safeTransferFrom(
            address(this),
            offer.seller,
            offer.assetId,
            offer.amount,
            ""
        );
        emit CancelOffer(offerID, eventIdCancelOffer);
    }

    function _getOwnerOffer(bytes32 id) internal view returns (Offer storage) {
        Offer storage offer = offers[id];
        return offer;
    }

    function buyOffer(
        bytes32 id,
        uint256 amount,
        uint256 eventIdSwapped
    ) external payable override {
        Offer memory offer = offers[id];
        require(msg.value > 0, "price must be > 0");
        require(offer.isForSell, "Offer not for sell");
        require(
            offer.expiresAt > block.timestamp,
            "Marketplace: offer expired"
        );
        _buyOffer(offer, id, amount, _msgSender());
        emit Swapped(
            _msgSender(),
            offer.seller,
            offer.collection,
            offer.assetId,
            msg.value,
            eventIdSwapped
        );
    }

    /*
        This method is introduced to buy NFT with the help of a delegate.
        It will work as like buyOffer method, but instead transferring NFT to _msgSender address, it will transfer the NFT to buyer address.
        As its a payable method, it's highly unlikely that somebody would call this function for fishing or by mistake.
    */
    function delegateBuy(
        bytes32 id,
        uint256 amount,
        address buyer,
        uint256 eventIdSwapped
    ) external payable {
        Offer memory offer = offers[id];
        require(buyer != address(0), "Marketplace: Buyer address is not valid");

        require(amount > 0, "Marketplace: Amount must be greater than zero");

        require(msg.value > 0, "price must be > 0");
        require(offer.isForSell, "Offer not for sell");
        require(
            offer.expiresAt > block.timestamp,
            "Marketplace: offer expired"
        );
        _buyOffer(offer, id, amount, buyer);
        emit Swapped(
            buyer,
            offer.seller,
            offer.collection,
            offer.assetId,
            msg.value,
            eventIdSwapped
        );
    }

    function _buyOffer(
        Offer memory offer,
        bytes32 offerId,
        uint256 amount,
        address buyer
    ) internal {
        IERC1155 multipleNFTCollection = IERC1155(offer.collection);
        (uint256 ownerProfitAmount, uint256 sellerAmount) = BullzLibrary
            .computePlateformOwnerProfitByAmount(
                msg.value,
                offer.price,
                amount,
                getFeebyIndex(offer.shareIndex)
            );
        (bool success, ) = address(offer.collection).call(
            abi.encodeWithSignature("isLoyalty()")
        );
        if (success) {
            (address creator, uint256 creatorBenif) = ILoyalty(offer.collection)
                .computeCreatorLoyaltyByAmount(
                    offer.assetId,
                    offer.seller,
                    sellerAmount
                );
            if (creatorBenif > 0) {
                TransferHelper.safeTransferETH(creator, creatorBenif);
                sellerAmount = sellerAmount.sub(creatorBenif);
            }
        }
        offers[offerId].amount = BullzLibrary
            .extractPurshasedAmountFromOfferAmount(offer.amount, amount);
        TransferHelper.safeTransferETH(offer.seller, sellerAmount);
        TransferHelper.safeTransferETH(owner(), ownerProfitAmount);
        multipleNFTCollection.safeTransferFrom(
            address(this),
            buyer,
            offer.assetId,
            amount,
            new bytes(0)
        );
        if (offer.amount == 0) delete offers[offerId];
    }

    function safePlaceBid(
        bytes32 _offer_id,
        uint256 _price,
        uint256 _amount,
        uint256 eventIdBidCreated
    ) external override {
        _createBid(_offer_id, _price, _amount, eventIdBidCreated);
    }

    function _createBid(
        bytes32 offerID,
        uint256 _price,
        uint256 _amount,
        uint256 eventIdBidCreated
    ) internal {
        require(_amount > 0, "Marketplace: Amount must be greater than zero");
        require(_price > 0, "Marketplace: Price must be greater than zero");

        // Checks order validity
        Offer memory offer = offers[offerID];
        // check on expire time
        Bid memory bid = bidforAuctions[offerID][_msgSender()];
        require(bid.id == 0, "bid already exists");
        require(offer.isForAuction, "NFT Marketplace: NFT token not in sell");
        require(
            offer.expiresAt > block.timestamp,
            "Marketplace: offer expired"
        );
        require(
            IERC20(offer.token).allowance(_msgSender(), address(this)) >=
                _price,
            "NFT Marketplace: Allowance error"
        );
        // Create bid
        bytes32 bidId = keccak256(
            abi.encodePacked(block.timestamp, msg.sender, _price)
        );

        // Save Bid for this order
        bidforAuctions[offerID][_msgSender()] = Bid({
            id: bidId,
            bidder: _msgSender(),
            token: offer.token,
            price: _price,
            amount: _amount
        });

        emit BidCreated(
            bidId,
            offer.collection,
            offer.assetId,
            _msgSender(), // bidder
            offer.token,
            _price,
            _amount,
            eventIdBidCreated
        );
    }

    function cancelBid(
        bytes32 _offerId,
        address _bidder,
        uint256 eventIdBidCancelled
    ) external override {
        Offer memory offer = _getOwnerOffer(_offerId);
        require(
            _bidder == _msgSender() || _msgSender() == offer.seller,
            "Marketplace: Unauthorized operation"
        );
        Bid memory bid = bidforAuctions[_offerId][_msgSender()];
        delete bidforAuctions[_offerId][_bidder];
        emit BidCancelled(bid.id, eventIdBidCancelled);
    }

    function acceptBid(
        bytes32 _offerID,
        address _bidder,
        uint256 eventIdBidSuccessful
    ) external override onlyOfferOwner(_offerID) {
        require(_bidder != address(0), "Marketplace: Bidder address not valid");
        //get offer
        Offer memory offer = _getOwnerOffer(_offerID);
        // get bid to accept
        Bid memory bid = bidforAuctions[_offerID][_bidder];

        require(
            offer.seller == _msgSender(),
            "Marketplace: unauthorized sender"
        );
        require(offer.isForAuction, "Marketplace: offer not in auction");
        require(
            offer.amount >= bid.amount,
            "Marketplace: insufficient balance"
        );

        // get service fees
        (uint256 ownerProfitAmount, uint256 sellerAmount) = BullzLibrary
            .computePlateformOwnerProfit(
                bid.price,
                bid.price,
                getFeebyIndex(offer.shareIndex)
            );

        (bool success, ) = address(offer.collection).call(
            abi.encodeWithSignature("isLoyalty()")
        );
        if (success) {
            (address creator, uint256 creatorBenif) = ILoyalty(offer.collection)
                .computeCreatorLoyaltyByAmount(
                    offer.assetId,
                    offer.seller,
                    sellerAmount
                );
            if (creatorBenif > 0) {
                TransferHelper.safeTransferFrom(
                    bid.token,
                    bid.bidder,
                    creator,
                    creatorBenif
                );
                sellerAmount = sellerAmount.sub(creatorBenif);
            }
        }
        // transfer escrowed bid amount minus market fee to seller
        TransferHelper.safeTransferFrom(
            bid.token,
            bid.bidder,
            _msgSender(),
            sellerAmount
        );
        TransferHelper.safeTransferFrom(
            bid.token,
            bid.bidder,
            owner(),
            ownerProfitAmount
        );

        offer.amount = BullzLibrary.extractPurshasedAmountFromOfferAmount(
            offer.amount,
            bid.amount
        );
        // Transfer NFT asset
        IERC1155(offer.collection).safeTransferFrom(
            address(this),
            bid.bidder,
            offer.assetId,
            bid.amount,
            ""
        );
        delete bidforAuctions[_offerID][_bidder];
        if (offer.amount == 0) delete offers[_offerID];
        emit BidAccepted(bid.id);
        // Notify ..
        emit BidSuccessful(
            offer.collection,
            offer.assetId,
            bid.token,
            bid.bidder,
            bid.price,
            bid.amount,
            eventIdBidSuccessful
        );
    }
}