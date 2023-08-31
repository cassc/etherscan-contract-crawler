// SPDX-License-Identifier: MIT

// Author: [email protected]
// Description: ERC721 smart contract Spartans NFTs on Ethereum for https://twitter.com/Spartans_NFT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Spartans is ERC721, Ownable {
    using Counters for Counters.Counter;

    string private baseURIExtended = "ipfs://bafybeigj6kj4qobtcinojfffrxnr2zocqiwbzg4icgqgtweuwfd63dveom/";

    Counters.Counter public tokenId;
    Counters.Counter public whitelistNftMinted;

    uint256 public MAX_SUPPLY = 300;
    uint256 public WL_MAX_SUPPLY = 280;

    uint256 public OG_PRICE = 50000000;
    uint256 public WL_PRICE = 75000000 ;
    uint256 public PUBLIC_PRICE = 99000000;

    uint256 public mintPhase = 0;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public og;

    constructor() ERC721("Spartans", "SPT") {}

    function updateMintPhase(uint256 _mintPhase) external onlyOwner {
        mintPhase = _mintPhase;
    }

    function updateMaxSupply(uint256 _maxSupply) external onlyOwner {
        MAX_SUPPLY = _maxSupply;
    }

    function updateWhitelistMaxSupply(uint256 _whitelistMaxSupply) external onlyOwner {
        WL_MAX_SUPPLY = _whitelistMaxSupply ;
    }

    function updateOgPrice(uint256 _ogPrice) external onlyOwner {
        OG_PRICE = _ogPrice;
    }

    function updateWhitelistPrice(uint256 _whitelistPrice) external onlyOwner {
        WL_PRICE = _whitelistPrice;
    }

    function updatePublicPrice(uint256 _publicPrice) external onlyOwner {
        PUBLIC_PRICE = _publicPrice;
    }

    function addToOgOrWhitelist(address[] memory addresses, uint8 listType) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            if(listType == 1 && !og[addr]) og[addr] = true;
            if(listType == 2 && !whitelist[addr]) whitelist[addr] = true;
        }
    }

    function removeToOgOrWhitelist(address[] memory addresses, uint8 listType) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            if(listType == 1 && !og[addr]) og[addr] = false;
            if(listType == 2 && !whitelist[addr]) whitelist[addr] = false;
        }
    }

    function mintReserved(uint256 amount, address _address) external onlyOwner {
        require(tokenId.current() + amount <= MAX_SUPPLY, "Not enough tokens left to mint");

        for (uint256 i = 0; i < amount; i++) {
            tokenId.increment();
            _safeMint(_address, tokenId.current());
        }
    }

    function mintOgOrWhitelist() external payable {
        require(tokenId.current() < MAX_SUPPLY, "Not enough tokens left to mint");
        require(mintPhase == 1, "OG and Whitelist mint not active");
        require(og[msg.sender] || whitelist[msg.sender], "You are not allowed to mint as OG or whitelist");

        if(og[msg.sender]) {
            require(msg.value >= OG_PRICE, "Not enough funds");
            og[msg.sender] = false;
        }

        if(whitelist[msg.sender]) {
            require(msg.value >= WL_PRICE, "Not enough funds");
            require(whitelistNftMinted.current() < WL_MAX_SUPPLY, "Whitelist mint sold out");
            whitelistNftMinted.increment();
            whitelist[msg.sender] = false;
        }

        tokenId.increment();
        _safeMint(msg.sender, tokenId.current());
    }

    function mintPublic() external payable {
        require(tokenId.current() < MAX_SUPPLY, "Not enough tokens left to mint");
        require(mintPhase == 2, "Public mint not active");
        require(msg.value >= PUBLIC_PRICE, "Not enough funds");

        tokenId.increment();
        _safeMint(msg.sender, tokenId.current());
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURIExtended = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURIExtended;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is zero");
        payable(owner()).transfer(balance);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json")) : "";
    }

}