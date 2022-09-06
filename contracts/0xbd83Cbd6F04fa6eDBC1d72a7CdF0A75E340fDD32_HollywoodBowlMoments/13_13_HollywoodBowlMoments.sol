//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract HollywoodBowlMoments is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    constructor(
        string memory _name,
        string memory _short_name,
        uint256 _legendaryPrice,
        uint256 _rarePrice,
        uint256 _commonPrice,
        string memory _contractMetadataURI,
        string memory _baseTokenURI,
        bool _mintActive
    ) ERC721(_name, _short_name) {
        legendaryPrice = _legendaryPrice;
        rarePrice = _rarePrice;
        commonPrice = _commonPrice;
        contractMetadataURI = _contractMetadataURI;
        baseTokenURI = _baseTokenURI;
        mintActive = _mintActive;
    }

    // Shared Variables
    bool public mintActive;
    string public contractMetadataURI;
    string private baseTokenURI;

    // Legendary NFTs Variables
    uint256 public constant LEGENDARY_MAX_SUPPLY = 8;
    uint256 public legendaryPrice;
    Counters.Counter private legendaryTrack;

    // Rare NFTs Variables
    uint256 public constant RARE_MAX_SUPPLY = 32;
    uint256 public rarePrice;
    Counters.Counter private rareTrack;

    // Common NFTs Variables
    uint256 public constant COMMON_MAX_SUPPLY = 60;
    uint256 public commonPrice;
    Counters.Counter private commonTrack;

    function mintLegendary(uint256 _qty) external payable {
        require(mintActive, "Mint is not active");
        require(tx.origin == msg.sender, "No contract minting");
        require((legendaryTrack.current() + _qty) < (LEGENDARY_MAX_SUPPLY + 1), "More than max supply");
        require((_qty * legendaryPrice) == msg.value, "Invalid amount of ether sent for purchase");

        for (uint256 i; i < _qty; i++) {
            legendaryTrack.increment();
            _safeMint(msg.sender, legendaryTrack.current());
        }
    }

    function mintRare(uint256 _qty) external payable {
        require(mintActive, "Mint is not active");
        require(tx.origin == msg.sender, "No contract minting");
        require((rareTrack.current() + _qty) < (RARE_MAX_SUPPLY + 1), "More than max supply");
        require((_qty * rarePrice) == msg.value, "Invalid amount of ether sent for purchase");

        uint256 numberOfIdsToSkip = LEGENDARY_MAX_SUPPLY;
        for (uint256 i; i < _qty; i++) {
            rareTrack.increment();
            _safeMint(msg.sender, rareTrack.current() + numberOfIdsToSkip);
        }
    }

    function mintCommon(uint256 _qty) external payable {
        require(mintActive, "Mint is not active");
        require(tx.origin == msg.sender, "No contract minting");
    
        require((commonTrack.current() + _qty) < (COMMON_MAX_SUPPLY + 1), "More than max supply");
        require((_qty * commonPrice) == msg.value, "Invalid amount of ether sent for purchase");

        uint256 numberOfIdsToSkip = LEGENDARY_MAX_SUPPLY + RARE_MAX_SUPPLY;
        for (uint256 i; i < _qty; i++) {
            commonTrack.increment();
            _safeMint(msg.sender, commonTrack.current() + numberOfIdsToSkip);
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function totalSupply() public view returns (uint256) {
        return legendaryTrack.current() + rareTrack.current() + commonTrack.current();
    }

    function setLegendaryPrice(uint256 _legendaryPrice) external onlyOwner {
        legendaryPrice = _legendaryPrice;
    }

    function setRarePrice(uint256 _rarePrice) external onlyOwner {
        rarePrice = _rarePrice;
    }

    function setCommonPrice(uint256 _commonPrice) external onlyOwner {
        commonPrice = _commonPrice;
    }

    function setMintActive(bool _mintActive) external onlyOwner {
        mintActive = _mintActive;
    }

    function setContractMetadataURI(string memory _contractMetadataURI) external onlyOwner {
        contractMetadataURI = _contractMetadataURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function getCurrentLegendarySupply() public view returns (uint256) {
        return legendaryTrack.current();
    }

    function getCurrentRareSupply() public view returns (uint256) {
        return rareTrack.current();
    }

    function getCurrentCommonSupply() public view returns (uint256) {
        return commonTrack.current();
    }
}