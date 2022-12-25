// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ProofOfTomato is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string private _baseTokenURI;
    string public prerevealURL = 'ipfs://QmezhgdGzqUsGJbFomDwMKFsRqycd774dnjUmvx4S5wNyo/hidden.json';
    bool private _addJson = true;

    uint16 constant MAX_SUPPLY = 3333;

    bool private _publicSaleActive = false;

    mapping(address => uint) private _mintedPerAddress;

    constructor() ERC721A("Proof Of Tomato", "PT") Ownable() ReentrancyGuard() {
        _safeMint(msg.sender, 1);
     }
    
    function mint(uint16 quantity) public payable nonReentrant {
        
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Maximum amount reached");
    
        if (msg.sender != owner()) {

            require(quantity > 0 && quantity <= 20 && balanceOf(msg.sender) + quantity <= 20, "Minting is limited to max. 20 per wallet");

            MintInfo memory info = getMintInfo(msg.sender, quantity);
            require(info.canMint, "Public sale has not started");
            require(info.priceToPay <= msg.value, "Ether value sent is not correct");

            _mintedPerAddress[msg.sender] += quantity;
        }

        _safeMint(msg.sender, quantity);

    }

	function tokenURI(uint256 tokenId) public override view returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), (_addJson ? ".json" : "")))
            : prerevealURL;
	}

    function getMintInfo(address buyer, uint16 quantity) public view returns (MintInfo memory) {

        uint16 freeMintsAllowed = 1;

        uint256 _price = 0.005 ether;

        uint16 quantityToPay = quantity;

        if(_mintedPerAddress[buyer] == 0) {
            quantityToPay = quantity - freeMintsAllowed;
        }

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
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Maximum amount of mints reached");
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