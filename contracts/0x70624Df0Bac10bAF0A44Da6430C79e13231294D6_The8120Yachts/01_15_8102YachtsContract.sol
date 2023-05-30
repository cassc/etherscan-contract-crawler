// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract OGY {
    function ownerOf(uint256 tokenId) public virtual view returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);

    function balanceOf(address owner) external virtual view returns (uint256 balance);
}


contract The8120Yachts is Ownable, ERC721Enumerable, ReentrancyGuard {
    using SafeMath for uint256;

    OGY private immutable ogy;
    string public provenanceHash;
    string public baseURI;
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    uint256 public tokenIndex = 499;
    uint256 public constant PRICE = 25000000000000000; // 0.025 ETH
    uint256 public constant MAX_YACHTS = 3000;
    uint256 public constant MAX_PURCHASE = 15;
    uint256 public constant MAX_SUPPLY_PER_ADDRESS = 15;
    uint256 public constant PUBLIC_SALE_START = 1631977200;
    uint256 public constant PRE_SALE_START = 1631890800;
    uint256 public revealTimestamp = 1632582000;
    bool public isSaleHalted = false;
    bool private yachtsReserved = false;

    constructor(address ogyAddress, string memory uri) ERC721("The 8102: Yachts", "8102Y") {
        ogy = OGY(ogyAddress);
        baseURI = uri;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }

    function setProvenanceHash(string calldata hash) external onlyOwner {
        provenanceHash = hash;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function setRevealTimestamp(uint256 timeStamp) external onlyOwner {
        revealTimestamp = timeStamp;
    }

    function flipSaleState() external onlyOwner {
        isSaleHalted = !isSaleHalted;
    }

    function reserveYachts() external onlyOwner {
        require(!yachtsReserved, "Already reserved");
        require(tokenIndex.add(15) < MAX_YACHTS, "Exceeds max supply");
        for (uint256 i = 0; i < 15; i++) {
            tokenIndex += 1;
            _safeMint(msg.sender, tokenIndex);
        }
        yachtsReserved = true;
    }

    function claimYachts() external nonReentrant {
        require(block.timestamp > PRE_SALE_START, "Sale is not active");
        require(!isSaleHalted, "Sale halted");
        uint256 balance = ogy.balanceOf(msg.sender);
        require(balance > 0, "OGY required");

        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = ogy.tokenOfOwnerByIndex(msg.sender, i);
            if (!_exists(tokenId)) {
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function preSaleMint(uint256 numberOfTokens) external payable nonReentrant {
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        require(numberOfTokens <= MAX_PURCHASE, "Exceeds max tokens per tx");
        require(block.timestamp >= PRE_SALE_START, "Sale is not active");
        require(block.timestamp < PUBLIC_SALE_START, "Pre-Sale over");
        require(!isSaleHalted, "Sale halted");
        uint256 balance = ogy.balanceOf(msg.sender);
        require(balance > 0, "Ogy required");
        require(tokenIndex.add(numberOfTokens) < MAX_YACHTS, "Exceeds max supply");
        require(PRICE.mul(numberOfTokens) <= msg.value, "Wrong Eth value");
        require(balanceOf(msg.sender) + numberOfTokens <= MAX_SUPPLY_PER_ADDRESS + balance, "Exceeds max tokens / wallet");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            tokenIndex += 1;
            if (tokenIndex < MAX_YACHTS) {
                _safeMint(msg.sender, tokenIndex);
            }
        }
    }

    function mintYachts(uint256 numberOfTokens) external payable nonReentrant {
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        require(numberOfTokens <= MAX_PURCHASE, "Exceeds max tokens per tx");
        require(block.timestamp >= PUBLIC_SALE_START, "Sale not active");
        require(!isSaleHalted, "Sale halted");
        require(tokenIndex.add(numberOfTokens) < MAX_YACHTS, "Exceeds max supply");
        require(PRICE.mul(numberOfTokens) <= msg.value, "Wrong Eth value");
        uint256 balance = ogy.balanceOf(msg.sender);
        require(balanceOf(msg.sender) + numberOfTokens <= MAX_SUPPLY_PER_ADDRESS + balance, "Exceeds max tokens / wallet");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            tokenIndex += 1;
            if (tokenIndex < MAX_YACHTS) {
                _safeMint(msg.sender, tokenIndex);
            }
        }
    }

    function isMinted(uint256 tokenId) external view returns (bool) {
        require(tokenId < MAX_YACHTS, "tokenId outside collection bounds");

        return _exists(tokenId);
    }

    function setStartingIndex() external onlyOwner {
        require(startingIndex == 0, "Index already set");
        require(startingIndexBlock != 0, "Index block unset");
        require(block.timestamp >= revealTimestamp, "Not yet");

        startingIndex = uint256(blockhash(startingIndexBlock)) % MAX_YACHTS;

        if ((block.number - startingIndexBlock) > 255) {
            startingIndex = uint256(blockhash(block.number - 1)) % MAX_YACHTS;
        }

        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }
    }

    function setStartingIndexBlock() external onlyOwner {
        require(startingIndexBlock == 0, "Index block already set");
        require(startingIndex == 0, "Index already set");
        startingIndexBlock = block.number;
    }

    function mintUnclaimedOGYYachts() external onlyOwner {
        require(block.timestamp >= revealTimestamp);
        require(totalSupply() < MAX_YACHTS);
        for (uint256 i = 0; i < 500; i++) {
            if (!_exists(i)) {
                _safeMint(msg.sender, i);
            }
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}