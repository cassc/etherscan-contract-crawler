// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract NFTMarketplace is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    using ERC165Checker for address;
    using Address for address;

    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    struct FeeItem {
        address payable feeAccount; // the account that recieves fees
        uint256 feePercent; // the fee percentage on sales 1: 100, 50: 5000, 100: 10000
        uint256 marketFeePercent; // the fee percentage for market 1: 100, 50: 5000, 100: 10000
    }
    mapping(address => FeeItem) public _feeData;
    address private deadAddress = 0x0000000000000000000000000000000000000000;

    enum ListingStatus {
        Active,
        Sold,
        Cancelled
    }

    struct MarketItem {
        ListingStatus status;
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    event MarketItemSold(
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price
    );

    event MarketItemCancelled(
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price
    );

    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public nonReentrant {
        require(
            Address.isContract(nftContract),
            "The address must be the NFT contract address."
        );
        require(price > 0, "Price must be greater than 0.");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToMarketItem[itemId] = MarketItem(
            ListingStatus.Active,
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(msg.sender),
            price,
            false
        );

        require(
            idToMarketItem[itemId].price > 0,
            "Created market item's price must be greater than 0."
        );

        IERC721(nftContract).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            msg.sender,
            price,
            false
        );
    }

    function createMarketSale(address nftContract, uint256 itemId)
        public
        payable
        nonReentrant
    {
        require(
            Address.isContract(nftContract),
            "The address must be the NFT contract address."
        );
        uint256 price = idToMarketItem[itemId].price;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        MarketItem storage item = idToMarketItem[itemId];
        address seller = idToMarketItem[itemId].seller;
        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );
        require(!item.sold, "This Sale has alredy finnished");
        require(item.status == ListingStatus.Active, "Listing is not active");

        uint256 feeAmount = (_feeData[nftContract].feePercent * price) / 10000;
        uint256 marketFee = (_feeData[nftContract].marketFeePercent * price) /
            10000;
        // transfer the (item price - royalty amount - fee amount) to the seller
        (bool successSeller, ) = payable(item.seller).call{
            value: price - feeAmount - marketFee
        }("");
        require(
            successSeller,
            "Transfer to seller could not be processed. Please check your address and balance."
        );
        (bool successFee, ) = payable(_feeData[nftContract].feeAccount).call{
            value: feeAmount
        }("");
        require(
            successFee,
            "Transfer to royalty address could not be processed. Please check your address and balance."
        );

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        emit MarketItemSold(itemId, tokenId, seller, msg.sender, price);

        _itemsSold.increment();

        item.status = ListingStatus.Sold;
        item.owner = payable(msg.sender);
        item.sold = true;
    }

    function createMultiMarketSale(address[] calldata nftContracts, uint256[] calldata itemIds)
        public
        payable
    {
        require(nftContracts.length == itemIds.length, "Please input the nft Contract addresses and itemIDs as same length.");
        require(nftContracts.length > 0, "Please input one or more nfts info for multiple purchase.");

        uint256 len = nftContracts.length;
        for (uint256 i = 0; i < len; i++) {
            createMarketSale(nftContracts[i], itemIds[i]);
        }
    }

    function fetchMarketItems(address _sellerAddress, uint256 _status) public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](itemCount);
        if (_sellerAddress == deadAddress) {
            for (uint256 i = 0; i < itemCount; i++) {
                if (uint256(idToMarketItem[i + 1].status) == _status) {
                    uint256 currentId = i + 1;
                    MarketItem storage currentItem = idToMarketItem[currentId];
                    items[currentIndex] = currentItem;
                    currentIndex += 1;
                }
            }
        } else {
            for (uint256 i = 0; i < itemCount; i++) {
                if (uint256(idToMarketItem[i + 1].status) == _status && idToMarketItem[i + 1].seller == _sellerAddress) {
                    uint256 currentId = i + 1;
                    MarketItem storage currentItem = idToMarketItem[currentId];
                    items[currentIndex] = currentItem;
                    currentIndex += 1;
                }
            }
        }
        
        return items;
    }

    function cancelSale(uint256 _itemId) public {
        MarketItem storage item = idToMarketItem[_itemId];

        require(msg.sender == item.seller, "Only seller can cancel listing");
        require(item.status == ListingStatus.Active, "Listing is not active");

        IERC721(item.nftContract).transferFrom(
            address(this),
            msg.sender,
            item.tokenId
        );
        item.status = ListingStatus.Cancelled;
        item.sold = false;
        emit MarketItemCancelled(
            _itemId,
            item.tokenId,
            item.seller,
            item.owner,
            item.price
        );
    }

    //only owner
    function setFeeInfo(
        address nftContract,
        uint256 _marketFeePercent,
        uint256 _feePercent,
        address _feeAccount
    ) public onlyOwner {
        require(
            Address.isContract(nftContract),
            "The address must be the NFT contract address."
        );
        require(
            _feePercent + _marketFeePercent <= 10000,
            "The sum of fees already exceeded. Please add the reasonable values for them."
        );
        _feeData[nftContract].marketFeePercent = _marketFeePercent;
        _feeData[nftContract].feePercent = _feePercent;
        _feeData[nftContract].feeAccount = payable(_feeAccount);
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(
            success,
            "Withdrawal could not be processed. Please check your address and balance."
        );
    }
}