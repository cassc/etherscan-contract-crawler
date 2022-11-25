// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../interface/INFTingConfig.sol";
import "./NFTingBase.sol";

contract NFTingOffer is NFTingBase {
    using Counters for Counters.Counter;

    enum NFTingOfferState {
        ACTIVE,
        CANCELED,
        ACCEPTED,
        DECLINED
    }

    struct Offer {
        NFTingOfferState state;
        address nftAddress;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        address payable buyer;
        address payable seller;
    }

    Counters.Counter private currentOfferId;
    mapping(uint256 => Offer) internal offers;

    event OfferCreated(
        uint256 _offerId,
        address indexed _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        address indexed _buyer,
        uint256 _price,
        address indexed _seller
    );
    event OfferUpdated(uint256 _offerId, uint256 _newPrice);
    event OfferAccepted(uint256 _offerId);
    event OfferDeclined(uint256 _offerId);
    event OfferCancelled(uint256 _offerId);

    modifier isValidOffer(uint256 _offerId) {
        Offer storage offer = offers[_offerId];
        if (offer.seller == address(0)) {
            revert NotExistingOffer(_offerId);
        }

        _;
    }

    function makeOffer(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        address _seller
    )
        external
        payable
        onlyNFT(_nftAddress)
        isTokenOwnerOrApproved(_nftAddress, _tokenId, _amount, _seller)
    {
        if (_seller == msg.sender) {
            revert InvalidAddressProvided(_seller);
        } else if (msg.value == 0) {
            revert PriceMustBeAboveZero(msg.value);
        } else if (
            _amount == 0 ||
            (_amount > 1 &&
                _supportsInterface(_nftAddress, INTERFACE_ID_ERC721))
        ) {
            revert InvalidAmountOfTokens(_amount);
        }
        currentOfferId.increment();
        uint256 offerId = currentOfferId.current();

        Offer storage newOffer = offers[offerId];
        newOffer.nftAddress = _nftAddress;
        newOffer.tokenId = _tokenId;
        newOffer.amount = _amount;
        newOffer.buyer = payable(_msgSender());
        newOffer.price = msg.value;
        newOffer.seller = payable(_seller);
        newOffer.state = NFTingOfferState.ACTIVE;

        emit OfferCreated(
            offerId,
            _nftAddress,
            _tokenId,
            _amount,
            _msgSender(),
            msg.value,
            _seller
        );
    }

    function updateOffer(uint256 _offerId, uint256 _newPrice)
        external
        payable
        nonReentrant
        isValidOffer(_offerId)
    {
        Offer memory offer = offers[_offerId];
        offers[_offerId].price = _newPrice;

        if (offer.buyer != _msgSender()) {
            revert PermissionDenied();
        } else if (offer.state != NFTingOfferState.ACTIVE) {
            revert InvalidOfferState();
        } else if (_newPrice > offer.price) {
            if (msg.value < _newPrice - offer.price) {
                revert InsufficientETHProvided(msg.value);
            }
        } else if (_newPrice == 0) {
            revert PriceMustBeAboveZero(msg.value);
        } else if (_newPrice == offer.price) {
            revert PriceMustBeDifferent(_newPrice);
        } else if (_newPrice < offer.price) {
            offer.buyer.transfer(offer.price - _newPrice);
        }

        emit OfferUpdated(_offerId, _newPrice);
    }

    function acceptOffer(uint256 _offerId)
        external
        payable
        nonReentrant
        isValidOffer(_offerId)
        isApprovedMarketplace(
            offers[_offerId].nftAddress,
            offers[_offerId].tokenId,
            offers[_offerId].seller
        )
    {
        Offer memory offer = offers[_offerId];

        if (offer.seller != _msgSender()) {
            revert PermissionDenied();
        } else if (offer.state != NFTingOfferState.ACTIVE) {
            revert InvalidOfferState();
        }
        offers[_offerId].state = NFTingOfferState.ACCEPTED;

        _transfer721And1155(
            _msgSender(),
            offer.buyer,
            offer.nftAddress,
            offer.tokenId,
            offer.amount
        );

        uint256 rest = _payFee(offer.nftAddress, offer.tokenId, offer.price);
        offer.seller.transfer(rest);

        emit OfferAccepted(_offerId);
    }

    function declineOffer(uint256 _offerId)
        external
        nonReentrant
        isValidOffer(_offerId)
    {
        Offer memory offer = offers[_offerId];

        if (offer.seller != _msgSender()) {
            revert PermissionDenied();
        } else if (offer.state != NFTingOfferState.ACTIVE) {
            revert InvalidOfferState();
        }

        offers[_offerId].state = NFTingOfferState.DECLINED;

        offer.buyer.transfer(offer.price);

        emit OfferDeclined(_offerId);
    }

    function cancelOffer(uint256 _offerId)
        external
        nonReentrant
        isValidOffer(_offerId)
    {
        Offer memory offer = offers[_offerId];

        if (offer.buyer != _msgSender()) {
            revert PermissionDenied();
        } else if (offer.state != NFTingOfferState.ACTIVE) {
            revert InvalidOfferState();
        }

        offers[_offerId].state = NFTingOfferState.CANCELED;

        offer.buyer.transfer(offer.price);

        emit OfferCancelled(_offerId);
    }

    function getOfferDetailsById(uint256 _offerId)
        external
        view
        isValidOffer(_offerId)
        returns (
            address nftAddress,
            uint256 tokenId,
            uint256 amount,
            address buyer,
            uint256 price,
            address seller
        )
    {
        return (
            offers[_offerId].nftAddress,
            offers[_offerId].tokenId,
            offers[_offerId].amount,
            offers[_offerId].buyer,
            offers[_offerId].price,
            offers[_offerId].seller
        );
    }
}