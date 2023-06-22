// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MetaTrustDAO is Ownable, ERC721A, ReentrancyGuard {

    bool public publicSale;
	
    uint256 public constant MINT_PRICE_ETH = 0.03 ether;
    uint256 public constant MAX_TOKENS = 5000;
    uint256 public constant MAX_BATCH = 10;
	uint256 public constant DEV_AMOUNT = 722;
   
    address public constant PAYMENT_ADDRESS = 0xb92376FE898D899E636748D1e9A5f3fc779eFEF0;
    string private _baseTokenURI;
    mapping(address => uint256) private _tokensClaimed;

    constructor() ERC721A("MetaTrustDAO", "MTD", MAX_BATCH, MAX_TOKENS) {
	
    }

    function publicSaleMint(uint256 quantity) external payable nonReentrant {
        require(msg.sender == tx.origin);
        require(publicSale, "Not public");
        require(totalSupply() + quantity <= MAX_TOKENS, "Over max");
        require(MINT_PRICE_ETH * quantity == msg.value, "Bad ether val");
        _safeMint(msg.sender, quantity);
		_tokensClaimed[msg.sender] += quantity;
    }

    function devMint(address _to, uint256 quantity) external onlyOwner nonReentrant {
        require(quantity % MAX_BATCH == 0, "Req mult of 10");
		require(totalSupply() + quantity <= DEV_AMOUNT, "Too many");
        uint256 numChunks = quantity / MAX_BATCH;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(_to, MAX_BATCH);
        }
    }

    function setPublicSale(bool isPublic) external onlyOwner {
        publicSale = isPublic;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        payable(PAYMENT_ADDRESS).transfer(address(this).balance);     
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }
}