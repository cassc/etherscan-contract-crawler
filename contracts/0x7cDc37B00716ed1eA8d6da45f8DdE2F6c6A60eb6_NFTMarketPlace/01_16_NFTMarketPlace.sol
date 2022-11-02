// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketPlace is Ownable, ReentrancyGuard {
    uint256 marketFees = 0.010 ether;
    using Counters for Counters.Counter;
    Counters.Counter private itemId;
    Counters.Counter private itemsSold;

    struct NftMerketItem {
        address nftContract;
        uint256 id;
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool sold;
    }

    event NftMerketItemCreated(
        address indexed nftContract,
        uint256 indexed id,
        uint256 tokenId,
        address owner,
        address seller,
        uint256 price,
        bool sold
    );

    mapping(uint256 => NftMerketItem) private idForMarketItem;

    function createItemForSale(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external payable nonReentrant {
        require(price > 0, "price");
        require(tokenId > 0, "token Id");
        require(msg.value == marketFees, "marketfee");
        require(nftContract != address(0), "address");
        itemId.increment();
        uint256 id = itemId.current();

        idForMarketItem[id] = NftMerketItem(
            nftContract,
            id,
            tokenId,
            payable(address(0)),
            payable(msg.sender),
            price,
            false
        );
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        emit NftMerketItemCreated(nftContract, id, tokenId, address(0), msg.sender, price, false);
    }

    function createMarketForSale(address nftContract, uint256 nftItemId)
        external
        payable
        nonReentrant
    {
        uint256 price = idForMarketItem[nftItemId].price;
        uint256 tokenId = idForMarketItem[nftItemId].tokenId;
        require(msg.value == price, "price");
        (bool success1, ) = idForMarketItem[nftItemId].seller.call{value: msg.value}("");
        require(success1, "transfer to seller failed");

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idForMarketItem[nftItemId].owner = payable(msg.sender);
        idForMarketItem[nftItemId].sold = true;
        itemsSold.increment();

        (bool success2, ) = owner().call{value: marketFees}("");
        require(success2, "market fee transfer failed");
    }

    function getMyItemCreated() external view returns (NftMerketItem[] memory) {
        uint256 totalItemCount = itemId.current();
        uint256 myItemCount;
        uint256 myCurrentIndex;

        for (uint256 i; i < totalItemCount; i++) {
            if (idForMarketItem[i + 1].seller == msg.sender) {
                myItemCount += 1;
            }
        }
        NftMerketItem[] memory nftItems = new NftMerketItem[](myItemCount);
        for (uint256 i; i < totalItemCount; i++) {
            if (idForMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                NftMerketItem memory currentItem = idForMarketItem[currentId];
                nftItems[myCurrentIndex] = currentItem;
                myCurrentIndex += 1;
            }
        }
        return nftItems;
    }

    //Create My purchased Nft Item
    function getMyNFTPurchased() external view returns (NftMerketItem[] memory) {
        uint256 totalItemCount = itemId.current();
        uint256 myItemCount;
        uint256 myCurrentIndex;
        uint256 currentId;
        for (uint256 i; i < totalItemCount; i++) {
            if (idForMarketItem[i + 1].owner == msg.sender) {
                myItemCount += 1;
            }
        }
        NftMerketItem[] memory nftItems = new NftMerketItem[](myItemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idForMarketItem[i + 1].owner == msg.sender) {
                currentId = i + 1;
                NftMerketItem memory currentItem = idForMarketItem[currentId];
                nftItems[myCurrentIndex] = currentItem;
                myCurrentIndex += 1;
            }
        }
        return nftItems;
    }

    //Fetch  all unsold nft items
    function getAllUnsoldItems() external view returns (NftMerketItem[] memory) {
        uint256 totalItemCount = itemId.current();
        uint256 myItemCount = itemId.current() - itemsSold.current();
        uint256 myCurrentIndex;
        uint256 currentId;
        NftMerketItem[] memory nftItems = new NftMerketItem[](myItemCount);

        for (uint256 i; i < totalItemCount; i++) {
            if (idForMarketItem[i + 1].owner == address(0)) {
                currentId = i + 1;
                NftMerketItem memory currentItem = idForMarketItem[currentId];
                nftItems[myCurrentIndex] = currentItem;
                myCurrentIndex += 1;
            }
        }
        return nftItems;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }

    function gettheMarketFees() external view returns (uint256) {
        return marketFees;
    }
}