// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INFTGaugeFactory.sol";
import "./interfaces/INFTGauge.sol";
import "./interfaces/IVotingEscrow.sol";
import "./libraries/NFTs.sol";

contract EarlyAccess is Ownable {
    event AddCollection(address indexed collection);
    event WhitelistNFT(address indexed collection, uint256 tokenId);

    uint256 public amount;
    uint256 public limit;
    address public factory;
    address public votingEscrow;
    uint256 public maxDuration;

    uint256 public totalNumberWhitelisted;
    uint256 public launchedAt;
    mapping(address => bool) public collections;
    mapping(address => mapping(uint256 => bool)) public whitelisted;
    mapping(address => mapping(uint256 => bool)) public wrapped;

    constructor(uint256 _amount, uint256 _limit) {
        amount = _amount;
        limit = _limit;
    }

    function updateParameters(uint256 _amount, uint256 _limit) external onlyOwner {
        require(launchedAt == 0, "EA: LAUNCHED");
        amount = _amount;
        limit = _limit;
    }

    function setFactory(address _factory) external onlyOwner {
        factory = _factory;

        votingEscrow = INFTGaugeFactory(_factory).votingEscrow();
        maxDuration = IVotingEscrow(_factory).maxDuration();
    }

    function launch() external onlyOwner {
        require(launchedAt == 0, "EA: LAUNCHED");

        launchedAt = block.timestamp;
    }

    function addCollections(address[] calldata _collections) external onlyOwner {
        require(launchedAt == 0, "EA: LAUNCHED");
        for (uint256 i; i < _collections.length; i++) {
            collections[_collections[i]] = true;
            emit AddCollection(_collections[i]);
        }
    }

    function whitelistNFTs(address collection, uint256[] calldata tokenIds) external {
        require(launchedAt == 0, "EA: LAUNCHED");
        require(collections[collection], "EA: COLLECTION_NOT_ALLOWED");
        require(totalNumberWhitelisted + tokenIds.length <= limit, "EA: LIMIT_REACHED");

        for (uint256 i; i < tokenIds.length; i++) {
            require(NFTs.ownerOf(collection, tokenIds[i]) == msg.sender, "EA: FORBIDDEN");
            whitelisted[collection][tokenIds[i]] = true;

            emit WhitelistNFT(collection, tokenIds[i]);
        }
        totalNumberWhitelisted += tokenIds.length;
    }

    function wrapNFT(
        address collection,
        uint256 tokenId,
        uint256 dividendRatio
    ) external {
        require(launchedAt > 0, "EA: NOT_LAUNCHED");
        require(whitelisted[collection][tokenId], "EA: NOT_WHITELISTED");
        require(!wrapped[collection][tokenId], "EA: WRAPPED");

        wrapped[collection][tokenId] = true;

        NFTs.safeTransferFrom(collection, msg.sender, address(this), tokenId);

        address gauge = INFTGaugeFactory(factory).gauges(collection);
        INFTGauge(gauge).wrap(tokenId, dividendRatio, msg.sender, 0);

        IVotingEscrow(votingEscrow).createLockFor(msg.sender, amount, amount, maxDuration);
    }
}