// SPDX-License-Identifier: GPL-3.0 License
pragma solidity ^0.8.3;
import "./NFT.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    Counters.Counter private _itemsDeleted;
    address payable owner;
    uint256 listingPrice = 5;

    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        address payable creator;
        uint256 pricesps;
        bool sold;
        string collectionid;
        string categorie;
        bool isRoyaltyEnabled;
        uint256 royaltyAmount;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        address creator,
        uint256 pricesps,
        bool sold,
        string collectionid,
        string categorie,
        bool isRoyaltyEnabled,
        uint256 royaltyAmount
    );
    event MarketItemDeleted(uint256 indexed itemId);
    event ProductListed(uint256 indexed itemId);

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function createMarketItem(
        address nftContract,
        address creator,
        uint256 tokenId,
        uint256 pricesps,
        string memory collectionid,
        string memory categorie,
        bool isRoyaltyEnabled,
        uint256 royaltyAmount
    ) public payable nonReentrant {
        require(pricesps > 0, "Preco tem que ser maior que 0");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            payable(creator),
            pricesps,
            false,
            collectionid,
            categorie,
            isRoyaltyEnabled,
            royaltyAmount
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            creator,
            pricesps,
            false,
            collectionid,
            categorie,
            isRoyaltyEnabled,
            royaltyAmount
        );
    }

    function sellMarketItem(
        address nftContract,
        address creator,
        uint256 tokenId,
        uint256 pricesps,
        string memory collectionid,
        string memory categorie,
        bool isRoyaltyEnabled,
        uint256 royaltyAmount
    ) public payable nonReentrant {
        require(pricesps > 0, "El precio debe ser mayor a 0");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            payable(creator),
            pricesps,
            false,
            collectionid,
            categorie,
            isRoyaltyEnabled,
            royaltyAmount
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            creator,
            pricesps,
            false,
            collectionid,
            categorie,
            isRoyaltyEnabled,
            royaltyAmount
        );
    }

    function createMarketSale(address nftContract, uint256 itemId)
        public
        payable
        nonReentrant
    {
        IERC20 wsps = IERC20(0x8033064Fe1df862271d4546c281AfB581ee25C4A);
        uint256 price = idToMarketItem[itemId].pricesps;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        uint256 royalty = idToMarketItem[itemId].isRoyaltyEnabled
            ? idToMarketItem[itemId].royaltyAmount
            : 0;
        uint256 comission = (price * listingPrice) / 100;
        uint256 royaltycom = (price * royalty) / 100;
        uint256 pricelescom = (price - comission) - royaltycom;

        require(
            wsps.allowance(msg.sender, address(this)) >= price,
            "Insuficient Allowance"
        );
        require(
            wsps.balanceOf(msg.sender) >= price,
            "No tiene saldo suficiente"
        );
        require(wsps.transferFrom(msg.sender, address(this), price));
        require(wsps.transfer(idToMarketItem[itemId].seller, pricelescom));
        require(wsps.transfer(owner, comission));
        if (idToMarketItem[itemId].isRoyaltyEnabled) {
            wsps.transfer(idToMarketItem[itemId].creator, royaltycom);
        }
        // transfer the token from contract address to the buyer
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        _itemsSold.increment();
    }

    modifier onlyItemOwner(uint256 id) {
        require(
            idToMarketItem[id].seller == msg.sender ||
                idToMarketItem[id].owner == msg.sender,
            "Only product owner can do this operation"
        );
        _;
    }
    modifier onlyProductOrMarketPlaceOwner(uint256 id) {
        require(
            idToMarketItem[id].owner == address(this) ||
                idToMarketItem[id].seller == msg.sender,
            "Only product or market owner can do this operation"
        );
        _;
    }

    function deleteMarketItem(uint256 itemId, address nftContract)
        public
        payable
        onlyProductOrMarketPlaceOwner(itemId)
    {
        IERC20 wsps = IERC20(0x8033064Fe1df862271d4546c281AfB581ee25C4A);
        uint256 price = idToMarketItem[itemId].pricesps;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        uint256 comission = (price * listingPrice) / 100;
        require(
            wsps.allowance(msg.sender, address(this)) >= price,
            "Insuficient Allowance"
        );
        require(
            wsps.balanceOf(msg.sender) >= price,
            "No tiene saldo suficiente"
        );
        require(wsps.transfer(owner, comission));
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        delete idToMarketItem[itemId];
        _itemsDeleted.increment();
        emit MarketItemDeleted(itemId);
    }

    function transferFrom(address nftContract, uint256 itemId)
        public
        payable
        nonReentrant
    {
        //solhint-disable-next-line max-line-length
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        idToMarketItem[itemId].owner = payable(address(this));
        idToMarketItem[itemId].sold = false;
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    }

    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(0)) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].creator == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].creator == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}