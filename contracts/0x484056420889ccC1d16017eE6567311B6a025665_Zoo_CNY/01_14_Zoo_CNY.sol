//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./EIP712Whitelisting.sol";

// The Zoo Club Red Envelope NFT - ZhangKai.eth
// contract by @Jaasonft
// 新年快樂 !

contract Zoo_CNY is ERC721, EIP712Whitelisting {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string public baseURI;
    Counters.Counter private _tokenIdCounter;
    uint256 public maxSupply = 200;
    uint256 public maxMintPerWallet = 1;
    bool public publicMint = false;
    mapping(address => uint256) private amountMinted;

    constructor(string memory _baseURI) ERC721("The Zoo Club Red Envelope", "ZOOCNY") EIP712Whitelisting() {
        _tokenIdCounter.increment();
        baseURI = _baseURI;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setPublicMint(bool _state) external onlyOwner {
        publicMint = _state;
    }

    function addSupply(uint256 amount) external onlyOwner {
        maxSupply += amount;
    }

    function mint() external {
        require(msg.sender == tx.origin, "Calling from contract not allowed.");
        require(publicMint == true, "Public Mint not available");
        require(_tokenIdCounter.current() <= maxSupply, "Out of stock.");
        require(amountMinted[msg.sender] < maxMintPerWallet, "Max mint reached");
        _safeMint(msg.sender, _tokenIdCounter.current());
        amountMinted[msg.sender] += 1;
        _tokenIdCounter.increment();
    }

    function whitelistMint(bytes calldata signature) external {
        require(msg.sender == tx.origin, "Calling from contract not allowed.");
        require(_tokenIdCounter.current() <= maxSupply, "Out of stock.");
        require(check(signature));
        require(amountMinted[msg.sender] < maxMintPerWallet, "Max mint reached");
        _safeMint(msg.sender, _tokenIdCounter.current());
        amountMinted[msg.sender] += 1;
        _tokenIdCounter.increment();
    }

    function ownerMint(uint256 amount) external onlyOwner {
        for (uint256 i = 0; i < amount; i++) {
            require(_tokenIdCounter.current() <= maxSupply);
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId));
        string memory uri = string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
        return uri;
    }
}