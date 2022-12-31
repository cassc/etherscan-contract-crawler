// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IRoyaltyManager.sol";
import "./interfaces/IVCGNFT.sol";

contract VCGRoyaltyManager is IRoyaltyManager, Ownable {
    using SafeMath for uint256;

    address public marketplace;
    address public vcgNFT1155;
    address public vcgNFT721;

    uint256 immutable MAX_ROYALTY = 2000; // 20%

    constructor(address _marketplace) {
        setupMarketPlace(_marketplace);
    }

    modifier onlyCollectionOwner(address collectionAddress) {
        require(
            msg.sender == Ownable(collectionAddress).owner(),
            "VCGRoyaltyManager: not collection owner"
        );
        _;
    }

    modifier onlyMarketPlace() {
        require(
            msg.sender == marketplace,
            "VCGRoyaltyManager: not marketplace contract"
        );
        _;
    }

    modifier maxRoyalty(uint256 royalty) {
        require(royalty <= MAX_ROYALTY, "VCGRoyaltyManager: max royalty 20%");
        _;
    }

    mapping(address => CollectionInfo) collectionsInfo; // collection  => collectionInfo
    mapping(address => mapping(uint => CollectionInfo)) mainCollectionsInfo; // collection  => collectionInfo
    mapping(address => mapping(address => uint256)) public collectionsRoyalty; // collection => ERC address => amount royalties
    mapping(address => mapping(uint => mapping(address => uint))) public collectionVCGRoyalties; // collection => tokenId => ERC address => amount

    function setInfo(
        address collectionAddress,
        uint256 royalty,
        address taker
    ) public onlyCollectionOwner(collectionAddress) maxRoyalty(royalty) {
        collectionsInfo[collectionAddress] = CollectionInfo(royalty, taker);
    }

    function setInfoVCG(
        address collectionAddress,
        uint256 royalty,
        uint tokenId
    ) public maxRoyalty(royalty) {
        require(
            collectionAddress == vcgNFT1155 || collectionAddress == vcgNFT721,
            "VCGRoyaltyManager: not vcg main nft token"
        );
        address creator = IVCGNFT(collectionAddress).getCreator(tokenId);
        require(creator == msg.sender, "VCGRoyaltyManager: not token creator");
        mainCollectionsInfo[collectionAddress][tokenId] = CollectionInfo(
            royalty,
            creator
        );
    }

    function getCollectionRoyaltyInfo(address collectionAddress)
        external
        view
        returns (CollectionInfo memory)
    {
        return collectionsInfo[collectionAddress];
    }

    function getMainCollectionRoyaltyInfo(address collectionAddress, uint nftId)
        external
        view
        returns (CollectionInfo memory)
    {
        return mainCollectionsInfo[collectionAddress][nftId];
    }

    function addRoyalty(
        address collectionAddress,
        uint256 sellAmount,
        address _token,
        uint _nftId
    ) external onlyMarketPlace returns (uint256 royaltyFee) {
        if (collectionAddress == vcgNFT1155 || collectionAddress == vcgNFT721) {
            royaltyFee = sellAmount.div(10000).mul(
                mainCollectionsInfo[collectionAddress][_nftId].collectionRoyalty
            );

            collectionVCGRoyalties[collectionAddress][_nftId][
                _token
            ] = collectionVCGRoyalties[collectionAddress][_nftId][_token].add(
                royaltyFee
            );
        } else {
            royaltyFee = sellAmount.div(10000).mul(
                collectionsInfo[collectionAddress].collectionRoyalty
            );

            collectionsRoyalty[collectionAddress][_token] = collectionsRoyalty[
                collectionAddress
            ][_token].add(royaltyFee);
        }
    }

    function withdrawRoyalty(
        address collectionAddress,
        address _token,
        uint256 _nftId
    ) external onlyMarketPlace returns (uint256 totalRoyalty) {
        if (collectionAddress == vcgNFT1155 || collectionAddress == vcgNFT721) {
            totalRoyalty = collectionVCGRoyalties[collectionAddress][_nftId][
                _token
            ];
            require(totalRoyalty > 0, "VCGRoyaltyManager: royalty 0");

            collectionVCGRoyalties[collectionAddress][_nftId][_token] = 0;
        } else {
            totalRoyalty = collectionsRoyalty[collectionAddress][_token];
            require(totalRoyalty > 0, "VCGRoyaltyManager: royalty 0");

            collectionsRoyalty[collectionAddress][_token] = 0;
        }
    }

    function setupMarketPlace(address _marketplace) public onlyOwner {
        marketplace = _marketplace;
    }

    function setupVCGToken(address _vcgNFT1155, address _vcgNFT721)
        public
        onlyOwner
    {
        vcgNFT1155 = _vcgNFT1155;
        vcgNFT721 = _vcgNFT721;
    }

    function checkVCGNFT(address _collection) public view returns (bool) {
        return _collection == vcgNFT1155 || _collection == vcgNFT721;
    }
}