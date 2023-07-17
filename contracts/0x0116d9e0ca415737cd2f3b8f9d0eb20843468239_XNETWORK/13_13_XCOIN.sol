// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract XNETWORK is Ownable, ERC721A, ReentrancyGuard {
	uint256 public NFTSupply;
	uint256 public NFTMinted;

	string public _baseTokenURI;
	
    constructor() ERC721A("X-Network", "XPASS"){
       NFTSupply = 500;
    }
	
    function mintNFT(address[] calldata _to, uint256[] calldata _count) external onlyOwner nonReentrant {
        require(
		   _to.length == _count.length,
		   "Mismatch between address and count"
		);
		for(uint i=0; i < _to.length; i++){
		    require (
			  NFTMinted + _count[i] <= NFTSupply, 
			  "Max mint limit reached"
			);
		    _safeMint(_to[i], _count[i]);
		    NFTMinted += _count[i];
		}
    }
	
	function mintNFT(address[] calldata _to, uint256 _count) external onlyOwner nonReentrant {
		for(uint i=0; i < _to.length; i++){
		    require (
			  NFTMinted + _count <= NFTSupply, 
			  "Max mint limit reached"
			);
		    _safeMint(_to[i], _count);
		    NFTMinted += _count;
		}
    }
	
    function _baseURI() internal view virtual override returns (string memory) {
	   return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
	    _baseTokenURI = baseURI;
    }
	
    function numberMinted(address owner) public view returns (uint256) {
	   return _numberMinted(owner);
    }
	
	function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
	   return ownershipOf(tokenId);
	}
	
	function updateNFTSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= NFTMinted, "Incorrect value");
        NFTSupply = newSupply;
    }
}