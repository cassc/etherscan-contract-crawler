// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract memepass is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
        

    uint256 public PUBLIC_PRICE = 0.16 ether;
    
    uint256 public MAX_PER_TX = 2000;
    uint256 public MAX_PER_WALLET = 20;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public RESERVED = 0;

    bool public publicSaleOpen = false;
    
    string public baseExtension = '.json';
    string private _baseTokenURI;
 

    mapping(address => uint256) public _owners;
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function mint(uint256 quantity) external payable {
        require(quantity > 0, "quantity of tokens cannot be less than or equal to 0");
        if (msg.sender != owner()) {
            require(publicSaleOpen, "Public Sale is not open");
            require(quantity <= MAX_PER_TX, "exceed max per transaction");
            require(totalSupply() + quantity <= MAX_SUPPLY - RESERVED, "exceed max supply of tokens");
            require(msg.value >= PUBLIC_PRICE * quantity, "insufficient ether value");
        }
        _owners[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }


    function tokenURI(uint256 tokenID) public view virtual override returns (string memory) {
        require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");
        string memory base = _baseURI();
        require(bytes(base).length > 0, "baseURI not set");
        return string(abi.encodePacked(base, tokenID.toString(), baseExtension));
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /* *************** */
    /* OWNER FUNCTIONS */
    /* *************** */
    function giveAway(address to, uint256 quantity) external onlyOwner {
        require(quantity <= RESERVED);
        RESERVED -= quantity;
        _safeMint(to, quantity);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function setBaseExtension(string memory _newExtension) public onlyOwner {
        baseExtension = _newExtension;
    }

    function updateMaxPerTX(uint256 newLimit) external onlyOwner {
        MAX_PER_TX = newLimit;
    }

    function updateMaxPerWallet(uint256 newLimit) external onlyOwner {
        MAX_PER_WALLET = newLimit;
    }

    function startPublicSale(bool _publicsale) external onlyOwner {
        publicSaleOpen = _publicsale;
    }

    function changePublicSalePrice(uint256 price) external onlyOwner {
        PUBLIC_PRICE = price;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}