// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MightyJaxxMarketplace is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _saleIdCounter;

    address public platformRoyaltyReceiver;
    uint256 public platformRoyaltyPercentage;

    mapping(address => bool) public supportedCollections;
    mapping(bytes32 => bool) private isOnSale;
    mapping(uint256 => SaleDetails) public saleDetails;
    mapping(address => CollectionRoyaltyInfo) public collectionRoyaltyInfo;

    struct SaleDetails {
        uint256 id;
        address seller;
        address nftAddress;
        uint256 nftId;
        uint256 price;
    }

    struct CollectionRoyaltyInfo {
        address receiver;
        uint256 royaltyPercentage;
    }

    event TokenPutOnSale(address indexed seller, SaleDetails saleDetails);
    event TokenBought(
        address indexed buyer,
        address indexed seller,
        address indexed nftAddress,
        uint256 price,
        uint256 nftId
    );
    event TokenRemovedFromSale(
        address indexed seller,
        address indexed nftAddress,
        uint256 nftId,
        uint256 saleId
    );
    event TokenSalePriceUpdated(
        uint256 saleId,
        uint256 oldPrice,
        uint256 newPrice
    );
    event SupportedCollectionAdded(address indexed collectionAddress);
    event SupportedCollectionRemoved(address indexed collectionAddress);
    event PlatformRoyaltyInfoAdded(
        address indexed newReceiver,
        uint256 newPercentage
    );
    event CollectionRoyaltyInfoAdded(
        address indexed collection,
        address indexed receiver,
        uint256 percentage
    );

    constructor(address _receiver, uint256 _perc) {
        platformRoyaltyReceiver = _receiver;
        platformRoyaltyPercentage = _perc;
    }

    function putTokenOnSale(
        address _nftAddress,
        uint256 _nftId,
        uint256 _price
    ) external {
        require(supportedCollections[_nftAddress], "Unsuppported collection.");
        require(_price != 0, "Price is zero.");
        require(
            IERC721(_nftAddress).ownerOf(_nftId) == msg.sender,
            "Not NFT owner."
        );
        require(
            IERC721(_nftAddress).isApprovedForAll(msg.sender, address(this)),
            "NFT not approved."
        );

        bytes32 saleHash = keccak256(abi.encodePacked(_nftAddress, _nftId));
        require(!isOnSale[saleHash], "NFT already on sale.");

        _saleIdCounter.increment();
        uint256 saleId = _saleIdCounter.current();

        SaleDetails storage _saleDetails = saleDetails[saleId];

        _saleDetails.id = saleId;
        _saleDetails.seller = msg.sender;
        _saleDetails.nftAddress = _nftAddress;
        _saleDetails.nftId = _nftId;
        _saleDetails.price = _price;
        isOnSale[saleHash] = true;

        emit TokenPutOnSale(msg.sender, _saleDetails);
    }

    function buyTokenFromSale(uint256 _saleId) external payable nonReentrant {
        SaleDetails memory _saleDetails = saleDetails[_saleId];

        uint256 price = _saleDetails.price;
        uint256 nftId = _saleDetails.nftId;
        address seller = _saleDetails.seller;
        address nftAddress = _saleDetails.nftAddress;

        require(seller != address(0), "NFT not for sale.");
        require(msg.value >= price, "Insufficient buy amount.");

        {
            CollectionRoyaltyInfo memory _royaltyInfo = collectionRoyaltyInfo[
                nftAddress
            ];

            address collectionRoyaltyReceiver = _royaltyInfo.receiver;
            uint256 collectionRoyaltyPerc = _royaltyInfo.royaltyPercentage;

            uint256 collectionRoyalty = (price * collectionRoyaltyPerc) /
                10_000;
            uint256 platformRoyalty = (price * platformRoyaltyPercentage) /
                10_000;

            (bool sendToCollection, ) = collectionRoyaltyReceiver.call{
                value: collectionRoyalty
            }("");
            require(sendToCollection, "send to collection royalty failed.");

            (bool sendToPlatform, ) = platformRoyaltyReceiver.call{
                value: platformRoyalty
            }("");
            require(sendToPlatform, "send to platform royalty failed.");

            (bool sendToSeller, ) = seller.call{
                value: price - collectionRoyalty - platformRoyalty
            }("");
            require(sendToSeller, "send to seller failed.");

            if (msg.value - price > 0) {
                (bool sendToBuyer, ) = msg.sender.call{
                    value: msg.value - price
                }("");
                require(sendToBuyer, "send to buyer failed.");
            }
        }

        delete isOnSale[keccak256(abi.encodePacked(nftAddress, nftId))];
        delete saleDetails[_saleId];

        emit TokenBought(msg.sender, seller, nftAddress, price, nftId);

        IERC721(nftAddress).safeTransferFrom(seller, msg.sender, nftId);
    }

    function removeTokenFromSale(uint256 _saleId) external {
        SaleDetails memory _saleDetails = saleDetails[_saleId];

        uint256 nftId = _saleDetails.nftId;
        address seller = _saleDetails.seller;
        address nftAddress = _saleDetails.nftAddress;

        delete isOnSale[keccak256(abi.encodePacked(nftAddress, nftId))];
        delete saleDetails[_saleId];

        require(seller != address(0), "NFT not for sale.");
        require(msg.sender == seller, "Only seller can remove.");

        emit TokenRemovedFromSale(seller, nftAddress, nftId, _saleId);
    }

    function changeTokenSalePrice(uint256 _saleId, uint256 newPrice) external {
        SaleDetails storage _saleDetails = saleDetails[_saleId];

        address seller = _saleDetails.seller;
        uint256 oldPrice = _saleDetails.price;

        require(seller != address(0), "NFT not for sale.");
        require(msg.sender == seller, "Only seller can update.");

        _saleDetails.price = newPrice;

        emit TokenSalePriceUpdated(_saleId, oldPrice, newPrice);
    }

    function addSupportedCollection(address _collectionAddress)
        external
        onlyOwner
    {
        supportedCollections[_collectionAddress] = true;

        emit SupportedCollectionAdded(_collectionAddress);
    }

    function removeSupportedCollection(address _collectionAddress)
        external
        onlyOwner
    {
        supportedCollections[_collectionAddress] = false;

        emit SupportedCollectionRemoved(_collectionAddress);
    }

    function setPlatformRoyaltyInfo(
        address _royaltyReceiver,
        uint256 _percentage
    ) external onlyOwner {
        platformRoyaltyReceiver = _royaltyReceiver;
        platformRoyaltyPercentage = _percentage;

        emit PlatformRoyaltyInfoAdded(_royaltyReceiver, _percentage);
    }

    function setCollectionRoyaltyInfo(
        address _collection,
        address _royaltyReceiver,
        uint256 _royaltyPercentage
    ) external onlyOwner {
        CollectionRoyaltyInfo
            storage _collectionRoyaltyInfo = collectionRoyaltyInfo[_collection];

        _collectionRoyaltyInfo.receiver = _royaltyReceiver;
        _collectionRoyaltyInfo.royaltyPercentage = _royaltyPercentage;

        emit CollectionRoyaltyInfoAdded(
            _collection,
            _royaltyReceiver,
            _royaltyPercentage
        );
    }

    function fundsAvailable() public view returns (uint256 contractBalance) {
        return address(this).balance;
    }

    function withdrawFunds() external onlyOwner {
        uint256 contractBal = fundsAvailable();

        (bool sent, ) = msg.sender.call{value: contractBal}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}