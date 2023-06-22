// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTTACOS is ERC721, ERC721Enumerable, Ownable {
    constructor() ERC721("NFTacos", "NFTACOS") {}

    bool public saleActive = false;
    
    event tacosMinted(uint256 tokenId); // Anti sniping protection

    string public _tokenUri = "http://assets.nftacos.xyz/"; // Initial base URI
    uint256 public ogtacos = 1;
    uint256 public kingtacos = 9482;

    // Price and supply definition
    uint256 constant public KING_TACOS_PRICE = 8 ether; 
    uint256 constant public OG_TACOS_PRICE = 0.05 ether; 
    uint256 constant public KING_TACOS_SUPPLY = 10000;
    uint256 constant public OG_TACOS_SUPPLY = 9481;

    function cookOgTacos(uint256 quantity) public payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(saleActive, "The sale is not active");
        require(quantity > 0, "You can't mint 0");
        require(msg.value == OG_TACOS_PRICE * quantity, "Wrong price");
        require(ogtacos + quantity <= OG_TACOS_SUPPLY, "No more OG Tacos left");

        for(uint256 i = 0; i < quantity; ++i) {
            _safeMint(msg.sender, ogtacos);
            emit tacosMinted(ogtacos);
            ogtacos++;
        }

        uint256 totalPaid = OG_TACOS_PRICE * quantity;
        payable(0x1ae6A4d3078b951438d1aa64DE6C1E4e033913D6).transfer(totalPaid * 15 / 100);
        payable(0xBC051c9004b9B83429A352c11846df2D8Db06E24).transfer(totalPaid * 15 / 100);
        payable(0x91eAd6E5cd9009EF213783E376B7AA6DD4ca8185).transfer(totalPaid * 70 / 100);
    }

    function cookKingTacos(uint256 quantity) public payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(saleActive, "The sale is not active");
        require(quantity > 0, "You can't mint 0");
        require(msg.value == KING_TACOS_PRICE * quantity, "Wrong price");
        require(kingtacos + quantity <= KING_TACOS_SUPPLY, "No more King Tacos left");

        for(uint256 i = 0; i < quantity; ++i) {
            _safeMint(msg.sender, kingtacos);
            emit tacosMinted(kingtacos);
            kingtacos++;
        }

        uint256 totalPaid = OG_TACOS_PRICE * quantity;
        payable(0x8B93f4e5E4d85a941d790857d68B685DAF02b2B6).transfer(totalPaid);
    }

    function airdropOg(address receiver) public onlyOwner {
        _safeMint(receiver, ogtacos);
        emit tacosMinted(ogtacos);
        ogtacos++;
    }

    // Toggle the sales
    function toggleSales() public onlyOwner {
        saleActive = !saleActive;
    }
    
	/*
	 * Helper function
	 */
	function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) return new uint256[](0);
		else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = 0; index < tokenCount; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
			return result;
		}
	}

    // Withdraw funds from the contract
    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    /** OVERRIDES */
    function _baseURI() internal view override returns (string memory) {
        return _tokenUri;
    }
    
	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}