/*

 _____                                     _       
|   __|___ ___ ___ ___ ___ ___ ___ ___ ___| |_ ___ 
|  |  | . |  _| . | . |   |- _| . |  _| .'|  _|_ -|
|_____|___|_| |_  |___|_|_|___|___|_| |__,|_| |___|
              |___|                                

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


interface ICheese {
  
    function balanceOf(address owner) external view returns (uint256); 

}

contract Gorgonzorats is ERC721A, Ownable, ReentrancyGuard {
    
    ICheese private Cheese = ICheese(0x06971F85c9e0Ba82e9bc4c7bE54f601ddEd00835); 
    
    using Strings for uint256;

    bytes32 public root;

    string private _baseTokenURI;
    string public prerevealURL = 'ipfs://rats/';
    bool private _addJson = true;

    mapping (address => bool) public CheeseOwnerMinted;

    uint16 constant MAX_RAT = 6666;

    uint256 totalPublicMinted = 0;

    uint16 constant MAX_PUBLIC = 3333;

    bool private _publicSaleActive = false;

    mapping(address => uint) private _mintedPerAddress;

    mapping(address => uint) private _CheesesMinted;

    constructor() ERC721A("Gorgonzorats", "GZR") Ownable() ReentrancyGuard() { }
    
    function mint(uint16 quantity) public payable nonReentrant {
        
        require(_totalMinted() + quantity <= MAX_RAT, "Maximum amount of rats reached");

        uint availableAmount = Cheese.balanceOf(msg.sender) - _CheesesMinted[msg.sender];
        
        if (msg.sender != owner()) {

            if (availableAmount > 0) {

            require(quantity > 0 && availableAmount >= quantity, "Error: make sure the quantity matches the amount of cheese you own.");

            _mintedPerAddress[msg.sender] += quantity;

            _CheesesMinted[msg.sender] += quantity;

            _safeMint(msg.sender, quantity);
            
            } else {
        
            require(quantity + totalPublicMinted <= MAX_PUBLIC);
            
            require(quantity > 0 && 20 >= quantity, "Minting is limited to max. 20 per wallet");

            MintInfo memory info = getMintInfo(msg.sender, quantity);

            require(info.canMint, "Public sale has not started");

            require(info.priceToPay <= msg.value, "Ether value sent is not correct");

            _mintedPerAddress[msg.sender] += quantity;

            totalPublicMinted += quantity;

            _safeMint(msg.sender, quantity);
            
            }

        }

    }

    function getMintInfo(address buyer, uint16 quantity) public view returns (MintInfo memory) {

        uint256 _price = 0.01 ether;

        uint16 quantityToPay = quantity;

        return MintInfo(
            /* unitPrice */ _price,
            /* undiscountedPrice */ _price * quantity,
            /* priceToPay */ _price * quantityToPay,
            /* canMint */ _publicSaleActive,
            /* totalMints */ quantity,
            /* mintsToPay */ quantityToPay);
    }

	function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

    function tokenURI(uint256 tokenId) public override view returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), (_addJson ? ".json" : "")))
            : prerevealURL;
	}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function mintedCount(address addressToCheck) external view returns (uint) {
        return _mintedPerAddress[addressToCheck];
    }

    function setPublicSale(bool publicSaleActive) external onlyOwner {
        _publicSaleActive = publicSaleActive;
    }

    function isPublicSale() public view returns (bool) {
        return _publicSaleActive;
    }    

    function shouldAddJson(bool value) external onlyOwner {
        _addJson = value;
    }

	function airdrop(address to, uint16 quantity) external onlyOwner {
        require(_totalMinted() + quantity <= MAX_RAT, "Maximum amount of mints reached");
		_safeMint(to, quantity);
	}

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}

struct MintInfo {
    uint256 unitPrice;
    uint256 undiscountedPrice;
    uint256 priceToPay;
    bool canMint;
    uint16 totalMints;
    uint16 mintsToPay;
}