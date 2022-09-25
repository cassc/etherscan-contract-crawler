// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EternalMarket is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _itemsSold;
    Counters.Counter private _items;

    uint256 listingPrice = 0.0075 ether;

    mapping(uint256 => MarketItem) private idToMarketItem;

    struct MarketItem {
        uint256 tokenId;
        IERC721 tokenContract;
        address payable seller;
        uint256 price;
        bool sold;
    }

    struct MarketItemWithId {
        uint256 id;
        uint256 tokenId;
        IERC721 tokenContract;
        address payable seller;
        uint256 price;
        bool sold;
    }

    event MarketItemCreated(
        uint256 indexed tokenId,
        IERC721 indexed tokenContract,
        address seller,
        uint256 price,
        bool sold
    );

    function createMarketItem(
        uint256 tokenId,
        IERC721 tokenContract,
        uint256 price
    ) public payable {
        require(price > 0, 'Price must be at least 1');
        require(
            msg.value == listingPrice,
            'Call value must be equal to listing price'
        );

        payable(owner()).transfer(msg.value);

        uint256 listingId = _items.current() + 1;
        _items.increment();

        idToMarketItem[listingId] = MarketItem(
            tokenId,
            tokenContract,
            payable(msg.sender),
            // payable(address(this)),
            price,
            false
        );

        tokenContract.transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            tokenId,
            tokenContract,
            msg.sender,
            price,
            false
        );
    }

    /* Used for cancelling items currently on sale */
    function cancelMarketItem(uint256 listingId) public {

        require(msg.sender == idToMarketItem[listingId].seller);

        idToMarketItem[listingId].sold = true;
        idToMarketItem[listingId].seller = payable(address(0));
        idToMarketItem[listingId].price = 0;

        _itemsSold.increment();

        idToMarketItem[listingId].tokenContract.transferFrom(address(this), msg.sender, idToMarketItem[listingId].tokenId);

        idToMarketItem[listingId].tokenContract = IERC721(address(0));
        idToMarketItem[listingId].tokenId = 0;
    }

    function buyMarketItem(uint256 listingId)
        public
        payable
    {

        uint256 price = idToMarketItem[listingId].price;
        address payable creator = idToMarketItem[listingId].seller;

        require(
            msg.value == price,
            'Please submit the asking price in order to complete the purchase'
        );

        idToMarketItem[listingId].tokenContract.transferFrom(address(this), msg.sender, idToMarketItem[listingId].tokenId);

        idToMarketItem[listingId].sold = true;
        idToMarketItem[listingId].seller = payable(address(0));
        idToMarketItem[listingId].price = 0;
        idToMarketItem[listingId].tokenContract = IERC721(address(0));
        idToMarketItem[listingId].tokenId = 0;

        _itemsSold.increment();

        uint256 adminFee = price.div(1000).mul(25);
        uint256 creatorPayout = price.div(1000).mul(975);

        payable(owner()).transfer(adminFee);
        payable(creator).transfer(creatorPayout);
    }

    function fetchMarketItems() public view returns (MarketItemWithId[] memory) {
        uint256 itemCount = _items.current();
        //uint256 unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItemWithId[] memory items = new MarketItemWithId[](itemCount);

        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].price > 0) {
                uint256 currentId = i + 1;

                MarketItem storage currentItem = idToMarketItem[currentId];
                // We have to convert over to another struct to figure out the order of the items.
                MarketItemWithId memory marketItemWithId;
                marketItemWithId.id = currentId;
                marketItemWithId.tokenId = currentItem.tokenId;
                marketItemWithId.tokenContract = currentItem.tokenContract;
                marketItemWithId.seller = currentItem.seller;
                marketItemWithId.price = currentItem.price;
                marketItemWithId.sold = currentItem.sold;

                items[currentIndex] = marketItemWithId;

                currentIndex += 1;
            }
        }

        return items;
    }

    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _items.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;

                MarketItem storage currentItem = idToMarketItem[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;
    }

    // Admin only functions
    function updateListingPrice(uint256 _listingPrice) public onlyOwner {
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // Only to be used when a listed NFT is inappropriate/breaks laws
    function cancelMarketItemAdmin(uint256 listingId)
        public
        onlyOwner
    {
        _itemsSold.increment();

        idToMarketItem[listingId].tokenContract.transferFrom(
            address(this),
            idToMarketItem[listingId].seller,
            idToMarketItem[listingId].tokenId
        );

        // Zero the listing
        idToMarketItem[listingId].sold = true;
        idToMarketItem[listingId].seller = payable(address(0));
        idToMarketItem[listingId].price = 0;
        idToMarketItem[listingId].tokenContract = IERC721(address(0));
        idToMarketItem[listingId].tokenId = 0;
    }
}