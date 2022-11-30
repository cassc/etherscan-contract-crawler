//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./lib/Vistor.sol";
import "./ERC721/ERC721.sol";

contract BZGTicket is ERC721,Vistor {

	uint256 private nftType = 1;
    uint256 private _tokenIndex = 0;
    
	constructor() ERC721("Bazinga Ticket","BZGT") public {
	}
	
	function setBaseURI(string memory _baseURI) onlyVistor public {
	    _setBaseURI(_baseURI);
	}
	
	function mint(address owner, uint256 grade) onlyVistor external returns(uint256) {
	    _tokenIndex++;
	    
		uint256 tokenId = nftType << 248 | grade << 128 | (block.timestamp << 64) | _tokenIndex;
	    _mint(owner, tokenId);
	    return tokenId;
	}
	
	function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "BFLand: caller is not owner nor approved");
        _burn(tokenId);
    }
    
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

}