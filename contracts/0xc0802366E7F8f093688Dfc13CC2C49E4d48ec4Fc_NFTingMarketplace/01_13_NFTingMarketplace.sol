// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./NFTingAuction.sol";
import "./NFTingOffer.sol";

contract NFTingMarketplace is NFTingAuction, NFTingOffer {
    using Counters for Counters.Counter;

    struct Listing {
        address nftAddress;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        address payable seller;
        uint256 collectionIndex;
        uint256 sellerIndex;
    }

    Counters.Counter private currentSaleId;

    mapping(uint256 => Listing) private listings;
    mapping(address => uint256[]) private collectionToListings;
    mapping(address => uint256[]) private sellerToListings;

    event ItemListed(
        uint256 indexed saleId,
        address indexed seller,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    );

    event ItemUpdated(uint256 indexed saleId, uint256 price);

    event ItemUnlisted(uint256 indexed saleId);

    event ItemBought(
        uint256 indexed saleId,
        address indexed buyer,
        uint256 price
    );

    modifier isListedOnSale(uint256 _saleId) {
        if (listings[_saleId].seller == address(0)) {
            revert NotListed();
        }
        _;
    }

    modifier isTokenSeller(uint256 saleId, address _seller) {
        if (listings[saleId].seller != _seller) {
            revert NotTokenSeller();
        }

        _;
    }

    modifier isNotTokenSeller(uint256 saleId, address _addr) {
        if (listings[saleId].seller == _addr) {
            revert TokenSeller();
        }

        _;
    }

    modifier isNotZeroPrice(uint256 _price) {
        if (_price == 0) {
            revert PriceMustBeAboveZero(_price);
        }

        _;
    }

    function _createListingOnSale(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price
    ) private returns (uint256 saleId) {
        currentSaleId.increment();
        saleId = currentSaleId.current();

        Listing storage newListing = listings[saleId];
        newListing.nftAddress = _nftAddress;
        newListing.tokenId = _tokenId;
        newListing.amount = _amount;
        newListing.price = _price;
        newListing.seller = payable(_msgSender());
        newListing.collectionIndex = collectionToListings[_nftAddress].length;
        newListing.sellerIndex = sellerToListings[_msgSender()].length;

        collectionToListings[_nftAddress].push(saleId);
        sellerToListings[_msgSender()].push(saleId);

        emit ItemListed(
            saleId,
            _msgSender(),
            _nftAddress,
            _tokenId,
            _amount,
            _price
        );
    }

    function listOnSale(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price
    )
        external
        isValidAddress(_nftAddress)
        isTokenOwnerOrApproved(_nftAddress, _tokenId, _amount, _msgSender())
        isNotZeroPrice(_price)
        isApprovedMarketplace(_nftAddress, _tokenId, _msgSender())
    {
        uint256 saleId = _createListingOnSale(
            _nftAddress,
            _tokenId,
            _amount,
            _price
        );

        _transfer721And1155(
            _msgSender(),
            address(this),
            listings[saleId].nftAddress,
            listings[saleId].tokenId,
            listings[saleId].amount
        );
    }

    function _deleteListingOnSale(uint256 _saleId) private {
        Listing storage listedItem = listings[_saleId];

        uint256[] storage cListings = collectionToListings[
            listedItem.nftAddress
        ];
        uint256[] storage sListings = sellerToListings[listedItem.seller];

        if (cListings.length > 1) {
            cListings[listedItem.collectionIndex] = cListings[
                cListings.length - 1
            ];
        }
        cListings.pop();

        if (sListings.length > 1) {
            sListings[listedItem.sellerIndex] = sListings[sListings.length - 1];
        }
        sListings.pop();

        delete listings[_saleId];
    }

    function unlistOnSale(uint256 _saleId)
        external
        isListedOnSale(_saleId)
        isTokenSeller(_saleId, _msgSender())
    {
        Listing storage listedItem = listings[_saleId];
        _transfer721And1155(
            address(this),
            _msgSender(),
            listedItem.nftAddress,
            listedItem.tokenId,
            listedItem.amount
        );

        _deleteListingOnSale(_saleId);

        emit ItemUnlisted(_saleId);
    }

    function buyItem(uint256 _saleId)
        external
        payable
        isListedOnSale(_saleId)
        isNotTokenSeller(_saleId, _msgSender())
    {
        Listing storage listedItem = listings[_saleId];
        if (msg.value < listedItem.price) {
            revert NotEnoughEthProvided();
        }

        if (!listedItem.seller.send(msg.value)) {
            revert TransactionError();
        }

        _transfer721And1155(
            address(this),
            _msgSender(),
            listedItem.nftAddress,
            listedItem.tokenId,
            listedItem.amount
        );

        _deleteListingOnSale(_saleId);

        emit ItemBought(_saleId, _msgSender(), msg.value);
    }

    function updateSalePrice(uint256 _saleId, uint256 _newPrice)
        external
        isListedOnSale(_saleId)
        isTokenSeller(_saleId, _msgSender())
    {
        listings[_saleId].price = _newPrice;

        emit ItemUpdated(_saleId, _newPrice);
    }

    function getListing(uint256 _saleId)
        external
        view
        isListedOnSale(_saleId)
        returns (
            address,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        return (
            listings[_saleId].nftAddress,
            listings[_saleId].tokenId,
            listings[_saleId].amount,
            listings[_saleId].price,
            listings[_saleId].seller
        );
    }

    function getListingsByCollection(address _nftAddress)
        public
        view
        returns (uint256[] memory)
    {
        return collectionToListings[_nftAddress];
    }

    function getListingsBySeller(address _seller)
        public
        view
        returns (uint256[] memory)
    {
        return sellerToListings[_seller];
    }
}