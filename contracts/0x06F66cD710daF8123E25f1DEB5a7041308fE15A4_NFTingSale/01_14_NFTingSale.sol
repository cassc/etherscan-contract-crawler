// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./NFTingBase.sol";

contract NFTingSale is NFTingBase {
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

    event ItemSold(
        uint256 indexed saleId,
        address indexed buyer,
        uint256 price
    );

    modifier onlyForSale(uint256 _saleId) {
        if (listings[_saleId].seller == address(0)) {
            revert NotListed();
        }
        _;
    }

    modifier isTokenSeller(uint256 _saleId, address _seller) {
        if (listings[_saleId].seller != _seller) {
            revert NotTokenSeller();
        }

        _;
    }

    modifier isNotTokenSeller(uint256 _saleId, address _addr) {
        if (listings[_saleId].seller == _addr) {
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
    }

    function listOnSale(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price
    )
        external
        onlyNFT(_nftAddress)
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
        Listing storage sale = listings[saleId];

        _transfer721And1155(
            _msgSender(),
            address(this),
            sale.nftAddress,
            sale.tokenId,
            sale.amount
        );

        emit ItemListed(
            saleId,
            _msgSender(),
            sale.nftAddress,
            sale.tokenId,
            sale.amount,
            sale.price
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
        nonReentrant
        onlyForSale(_saleId)
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
        nonReentrant
        onlyForSale(_saleId)
        isNotTokenSeller(_saleId, _msgSender())
    {
        Listing memory listedItem = listings[_saleId];
        uint256 buyPrice = _addBuyFee(listedItem.price);
        if (msg.value < buyPrice) {
            revert NotEnoughEthProvided(msg.value, buyPrice);
        }

        _transfer721And1155(
            address(this),
            _msgSender(),
            listedItem.nftAddress,
            listedItem.tokenId,
            listedItem.amount
        );

        _deleteListingOnSale(_saleId);

        uint256 rest = _payFee(
            listedItem.nftAddress,
            listedItem.tokenId,
            buyPrice
        );
        listedItem.seller.transfer(rest);

        emit ItemSold(_saleId, _msgSender(), buyPrice);
    }

    function updateSalePrice(uint256 _saleId, uint256 _newPrice)
        external
        onlyForSale(_saleId)
        isTokenSeller(_saleId, _msgSender())
    {
        listings[_saleId].price = _newPrice;

        emit ItemUpdated(_saleId, _newPrice);
    }

    function getListing(uint256 _saleId)
        external
        view
        onlyForSale(_saleId)
        returns (
            address nft,
            uint256 tokenId,
            uint256 amount,
            uint256 price,
            address seller
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