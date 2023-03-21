// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'lib/ERC721A/contracts/ERC721A.sol';
import 'lib/openzeppelin-contracts/contracts/access/Ownable.sol';

contract TheOutlanderNFT is ERC721A, Ownable {
    uint256 public immutable freeMintLimit = 444;
    uint256 public immutable MAX_SUPPLY = 4444;
    uint256 public mintPrice = 0.03 ether;
    uint256 public whitelistPrice = 0.025 ether;
    address private treasury = 0x40412774ad7710C39222459052B6B2Ef07344138;
    uint private whiteListMintLimit = 2;    
    uint256 private freeListMintLimit = 2;

    bool public freeListMintOpen = true;
    bool public whiteListMintOpen = true;

    string public baseURI;

    mapping(address => bool) whitelist;
    mapping(address => bool) freelist;

    constructor() ERC721A('OutlandersToken', 'OTL') {
    }


    function appendWhiteList(address[] calldata addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function removeWhiteList(address[] calldata addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
        }
    }

    function appendFreeList(address[] calldata addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            freelist[addresses[i]] = true;
        }
    }


    function freeMint() public payable {
        require(totalSupply() + 1 < freeMintLimit, "Free mint limit reached");
        require(balanceOf(msg.sender) < freeListMintLimit, "Mint limint exceeded");
        
        _safeMint(msg.sender, 1);
    }

    function whiteListMint() public payable {
        require(whiteListMintOpen, "White list mint closed");
        require(whitelist[msg.sender], "Sender not part of white list");
        require(balanceOf(msg.sender) < whiteListMintLimit, "Mint limint exceeded");
        require(msg.value == whitelistPrice, "No enough funds");
        _safeMint(msg.sender, 1);
    }

    function publicMint() public payable {
        require(msg.value == mintPrice, "No enough funds");
        require(totalSupply() + 1 < MAX_SUPPLY, "Max supply reached");
        _safeMint(msg.sender, 1);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }
    function closeWhiteListMint() external onlyOwner {
        whiteListMintOpen = false;
    }
    function _baseURI() internal view override virtual returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }
}