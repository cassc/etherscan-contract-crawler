// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract IOETheChosen is ERC721A, Ownable, ReentrancyGuard {

    string public baseURI; 

    uint256 public price;
    uint256 public walletLimit = 1;
    uint256 public maxSupply = 500;

    bool public publicSaleIsLive;

    mapping (address => uint256) public IoeClaimed;
    mapping (address => bool) public IoeSacrificed;

    constructor() ERC721A("IO.E | The chosen", "IOETC") {}

    function becomeChosen() external nonReentrant{

        require(IoeClaimed[msg.sender] < walletLimit);
        require(publicSaleIsLive, "The chosen must be patient!");
        require(totalSupply() + walletLimit <= maxSupply, "The chosen have been already been selected!");
        require(tx.origin == msg.sender, "The chosen must be those of a fine bloodline!");

        _mint(msg.sender, walletLimit);

        IoeClaimed[msg.sender] += walletLimit;
    }
    
    function sacrifice(uint256[] calldata tokenIds) external nonReentrant {
        for(uint256 i; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender);
            _burn(tokenId);
            unchecked {
                ++i;
            }
        }

        if (!IoeSacrificed[msg.sender]) {
            IoeSacrificed[msg.sender] = true;
        }
    }

    function ownerMint(uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply);

        _mint(msg.sender, amount);
    }

    function toggleSaleState() external onlyOwner {
        publicSaleIsLive = !publicSaleIsLive;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
      price = price_;
    }

    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
      walletLimit = maxPerWallet_;
    }

    function setmaxSupply(uint256 maxSupply_) external onlyOwner {
      maxSupply = maxSupply_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
    }

    function chosenBurned(address owner) view public returns (uint256) {
        return _numberBurned(owner);
    }

    function totalIOEBurned() view public returns (uint256) {
        return _totalBurned();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}