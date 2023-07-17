// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AngelsDevilsAlphaPass is Ownable, ERC721A, ReentrancyGuard {

    uint256 public constant MAX_TOKENS = 300;
    string private _baseTokenURI = "ipfs://QmP6FVSv23AQ2xbgAvbQTYxRNYKeKWamkXBchjVJ4D92V5/";
	
    constructor() ERC721A("AngelsDevilsAlphaPass", "ADAP", 1, MAX_TOKENS) {
        
    }

    function devMint(address[] calldata _to) external onlyOwner nonReentrant {
		require(totalSupply() + _to.length <= MAX_TOKENS, "Over max");
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], 1);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
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