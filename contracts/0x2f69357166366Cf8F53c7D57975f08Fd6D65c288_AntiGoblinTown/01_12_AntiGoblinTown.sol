// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";


contract AntiGoblinTown is ERC721A, Ownable {
    bool public SaleIsActive;
    bool public _alreadyReserved;
    uint8 public constant MaxPerTransaction = 10;
    uint16 public constant MaxTokens = 5000;
    uint256 public TokenPrice = 0.0077 ether;

    mapping(address => uint256) public MintCount;
    string private _baseTokenURI;

    modifier validMint(uint256 numTokens) {
        require(SaleIsActive, "Sale must be active in order to mint");
        require(numTokens <= MaxPerTransaction, "Higher than max per transaction");
        require(totalSupply() + numTokens <= MaxTokens, "Purchase more than max supply");
        _;
    }
    
    constructor(string memory baseURI) ERC721A("antigoblintown", "ANTIGOBLIN", MaxPerTransaction, MaxTokens) {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    function mint(uint256 numTokens) external payable validMint(numTokens) {
        uint256 cost = 0;
        if (MintCount[_msgSender()] > 0) {
            cost = numTokens * TokenPrice;
        }
        else if (numTokens > 1) {
            cost = (numTokens - 1) * TokenPrice;
        }

        require(msg.value >= cost, "Invalid payment amount");
        MintCount[_msgSender()] += numTokens;
        _safeMint(_msgSender(), numTokens);
    }

    function reserve() external onlyOwner {
        require(!_alreadyReserved);
        _alreadyReserved = true;
        _safeMint(_msgSender(), 50, false, "");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function toggleSaleState() external onlyOwner {
        SaleIsActive = !SaleIsActive;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}