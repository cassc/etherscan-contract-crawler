// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Azukifud is Ownable, ReentrancyGuard, ERC721Enumerable {
    using SafeMath for uint256;
    using Strings for uint256;
    mapping(address => bool) private whiteList;
    mapping(address => bool) private whiteListUse;
    string public baseURI;
    uint256 constant MAX_SUPPLY = 10000;
    uint256 constant AUCTION_PRICE = 0.05 ether;
    uint256 constant maxPurchase = 5;
    bool public saleIsActive = false;
    uint256 private currentIndex;
    mapping(address => uint256) public mintCounts;

    constructor() ERC721("Azuki FUD", "Azuki FUD") {
        baseURI = "ipfs://QmThVJFKWNH315Jt3um4EmbRK3TaYy9qFN9fJq1xZBKMVF/";
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mint(uint256 numberOfTokens) external payable nonReentrant {
        require(saleIsActive, "Sale must be active to mint token");
        require(numberOfTokens <= maxPurchase, "Can only mint 5 tokens at a time");
        require(currentIndex.add(numberOfTokens) <= MAX_SUPPLY, "Purchase would exceed max supply of token");
        require(AUCTION_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        mintCounts[msg.sender] += numberOfTokens;
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = currentIndex;
            currentIndex++;
            _safeMint(msg.sender, mintIndex);
        }
        uint256 costToMint = AUCTION_PRICE.mul(numberOfTokens);
        if (msg.value > costToMint) {
            Address.sendValue(payable(msg.sender), msg.value - costToMint);
        }
    }

    function whiteListMint() external nonReentrant {
        require(saleIsActive, "Sale must be active to mint token");
        require(whiteList[msg.sender],"Whitelist not found");
        require(!whiteListUse[msg.sender],"Whitelist has been used");
        require(currentIndex.add(1) <= MAX_SUPPLY, "Purchase would exceed max supply of token");
        mintCounts[msg.sender] += 1;
        uint256 mintIndex = currentIndex;
        currentIndex++;
        whiteListUse[msg.sender]=true;
        _safeMint(msg.sender, mintIndex);
    }

    function devMint(uint256 numberOfTokens) external onlyOwner {
        require(numberOfTokens <= maxPurchase, "Can only mint 5 tokens at a time");
        require(currentIndex.add(numberOfTokens) <= MAX_SUPPLY, "Purchase would exceed max supply of token");
        mintCounts[msg.sender] += numberOfTokens;
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = currentIndex;
            currentIndex++;
            _safeMint(msg.sender, mintIndex);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function totalSupply() public view override returns (uint256) {
        return currentIndex;
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        require(index < totalSupply(), "ERC721A: global index out of bounds");
        return index;
    }

    function addWhiteListAddresses(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whiteList[_addresses[i]] = true;
        }
    }

    function removeWhiteListAddresses(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whiteList[_addresses[i]] = false;
        }
    }

    function isAddressWhiteListed(address _address) external view returns (bool isWhiteListUser,bool isUse) {
        return (whiteList[_address],whiteListUse[_address]);
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }
}