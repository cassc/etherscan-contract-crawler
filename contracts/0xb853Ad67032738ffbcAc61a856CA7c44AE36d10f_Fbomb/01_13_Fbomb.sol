// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Fbomb is ERC721, Ownable {

    uint256 constant MAX_SUPPLY = 9999;

    mapping(address => uint256) private _whitelistMinted;
    mapping(address => uint256) private _presaleMinted;
    mapping(address => uint256) private _publicMinted;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    address verifier;
    string public baseTokenURI;
    string public hiddenTokenURI = 'ipfs://QmS8wQqihMheMStSfSXoCNrfJSswVX67QuXdFb98PyNnX5';
    uint256 public maxForSale = 9899;
    uint256 public whitelistStart = 1643651940; // 1/31/2022 5:59pm GMT
    uint256 public whitelistMaxMint = 2;
    uint256 public whitelistPrice = 0.06 ether;
    uint256 public presaleStart = 1643738340; // 2/1/2022 5:59pm GMT
    uint256 public presaleMaxMint = 1;
    uint256 public presalePrice = 0.07 ether;
    uint256 public publicStart = 1643824740; // 2/2/2022 5:59pm GMT
    uint256 public publicMaxMint = 5;
    uint256 public publicPrice = 0.08 ether;

    constructor(
    ) ERC721('F-Bomb', 'FBOMB') {
        verifier = msg.sender;
    }

    function whitelistMint(bytes memory signature, uint256 quantity)
    external payable
    validSignature(signature, 1)
    whitelistActive()
    {
        require(_whitelistMinted[msg.sender] + quantity <= whitelistMaxMint, 'MINT: Quantity is too high');
        require(msg.value == quantity * whitelistPrice, 'MINT: Value is too low');
        _whitelistMinted[msg.sender] += quantity;
        for(uint256 i = 0; i < quantity; i++) {
            if(_tokenIdTracker.current() < maxForSale) {
                _mintSale(msg.sender);
            }
        }
    }

    function presaleMint(bytes memory signature, uint256 quantity)
    external payable
    validSignature(signature, 2)
    presaleActive()
    {
        require(_presaleMinted[msg.sender] + quantity <= presaleMaxMint, 'MINT: Quantity is too high');
        require(msg.value == quantity * presalePrice, 'MINT: Value is too low');
        _presaleMinted[msg.sender] += quantity;
        for(uint256 i = 0; i < quantity; i++) {
            if(_tokenIdTracker.current() < maxForSale) {
                _mintSale(msg.sender);
            }
        }
    }

    function publicMint(uint256 quantity)
    external payable
    publicActive()
    {
        require(_publicMinted[msg.sender] + quantity <= publicMaxMint, 'MINT: Quantity is too high');
        require(msg.value == quantity * publicPrice, 'MINT: Value is too low');
        _publicMinted[msg.sender] += quantity;
        for(uint256 i = 0; i < quantity; i++) {
            if(_tokenIdTracker.current() < maxForSale) {
                _mintSale(msg.sender);
            }
        }
    }

    function adminMint(address to, uint256 quantity) external onlyOwner {
        for(uint256 i = 0; i < quantity; i++) {
            if(_tokenIdTracker.current() < MAX_SUPPLY) {
                if(maxForSale < MAX_SUPPLY) {
                    maxForSale += 1;
                }
                _mintSale(to);
            }
        }
    }

    function _mintSale(address to) internal {
        _tokenIdTracker.increment();
        _safeMint(to, _tokenIdTracker.current());
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_tokenIdTracker.current() >= tokenId && tokenId > 0, "Token doesn't exist");
        return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId))) : hiddenTokenURI;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns(uint256) {
        require(index < ERC721.balanceOf(owner), "Owner index out of bounds");
        uint256 count = 0;
        for(uint256 i = 1; i <= _tokenIdTracker.current(); i++) {
            if(ownerOf(i) == owner) {
                if(count == index) {
                    return i;
                }
                count++;
            }
        }
        return 0;
    }

    // MODIFIERS
    modifier validSignature(bytes memory signature, uint256 listType) {
        bytes32 messageHash = sha256(abi.encode(msg.sender, listType));
        require(ECDSA.recover(messageHash, signature) == verifier, 'MINT: Invalid signature');
        _;
    }

    modifier whitelistActive() {
        require(block.timestamp >= whitelistStart, 'MINT: Whitelist is not active');
        _;
    }

    modifier presaleActive() {
        require(block.timestamp >= presaleStart, 'MINT: Presale is not active');
        _;
    }

    modifier publicActive() {
        require(block.timestamp >= publicStart, 'MINT: Minting is not yet open to the public');
        _;
    }

    // ADMIN FUNCTIONS
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setBaseURI(string memory baseUri) external onlyOwner {
        baseTokenURI = baseUri;
    }

    function setWhitelistStart(uint256 start) external onlyOwner {
        whitelistStart = start;
    }

    function setWhitelistMaxMint(uint256 max) external onlyOwner {
        whitelistMaxMint = max;
    }

    function setWhitelistPrice(uint256 price) external onlyOwner {
        whitelistPrice = price;
    }

    function setPresaleStart(uint256 start) external onlyOwner {
        presaleStart = start;
    }

    function setPresaleMaxMint(uint256 max) external onlyOwner {
        presaleMaxMint = max;
    }

    function setPresalePrice(uint256 price) external onlyOwner {
        presalePrice = price;
    }

    function setPublicStart(uint256 start) external onlyOwner {
        publicStart = start;
    }

    function setPublicMaxMint(uint256 max) external onlyOwner {
        publicMaxMint = max;
    }

    function setPublicPrice(uint256 price) external onlyOwner {
        publicPrice = price;
    }

    function setMaxForSale(uint256 forSale) external onlyOwner {
        maxForSale = forSale;
    }
}