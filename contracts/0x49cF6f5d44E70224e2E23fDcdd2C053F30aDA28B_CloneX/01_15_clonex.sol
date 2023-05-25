// SPDX-License-Identifier: MIT

/*
    RTFKT Legal Overview [https://rtfkt.com/legaloverview]
    1. RTFKT Platform Terms of Services [Document #1, https://rtfkt.com/tos]
    2. End Use License Terms
    A. Digital Collectible Terms (RTFKT-Owned Content) [Document #2-A, https://rtfkt.com/legal-2A]
    B. Digital Collectible Terms (Third Party Content) [Document #2-B, https://rtfkt.com/legal-2B]
    C. Digital Collectible Limited Commercial Use License Terms (RTFKT-Owned Content) [Document #2-C, https://rtfkt.com/legal-2C]
    
    3. Policies or other documentation
    A. RTFKT Privacy Policy [Document #3-A, https://rtfkt.com/privacy]
    B. NFT Issuance and Marketing Policy [Document #3-B, https://rtfkt.com/legal-3B]
    C. Transfer Fees [Document #3C, https://rtfkt.com/legal-3C]
    C. 1. Commercialization Registration [https://rtfkt.typeform.com/to/u671kiRl]
    
    4. General notices
    A. Murakami Short Verbiage – User Experience Notice [Document #X-1, https://rtfkt.com/legal-X1]
*/

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract CloneXRandomizer {
    function getTokenId(uint256 tokenId) public view virtual returns(string memory);
}

contract CloneX is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("CloneX", "CloneX") {
        _tokenIdCounter.increment(); // Making sure we start at token ID 1
    }
    
    event CloneXRevealed(uint256 tokenId, string fileId); // Sending the event for offchain script to transform the right file
    
    address randomizerAddress; // Approved randomizer contract
    address mintvialAddress; // Approved mintvial contract
    string public _tokenUri = "https://clonex-assets.rtfkt.com/"; // Initial base URI
    
    bool public contractLocked = false;

    function mintTransfer(address to) public returns(uint256) {
        require(msg.sender == mintvialAddress, "Not authorized");
        
        CloneXRandomizer tokenAttribution = CloneXRandomizer(randomizerAddress);
        
        string memory realId = tokenAttribution.getTokenId(_tokenIdCounter.current());
        uint256 mintedId =  _tokenIdCounter.current();
        
        _safeMint(to, _tokenIdCounter.current());
        emit CloneXRevealed(_tokenIdCounter.current(), realId);
        _tokenIdCounter.increment();
        return mintedId;
    }

    // Change the randomizer address contract
    function setRandomizerAddress(address newAddress) public onlyOwner {
        randomizerAddress = newAddress;
    }
    
    // Change the mintvial address contract
    function setMintvialAddress(address newAddress) public onlyOwner { 
        mintvialAddress = newAddress;
    }
    
    function secureBaseUri(string memory newUri) public onlyOwner {
        require(contractLocked == false, "Contract has been locked and URI can't be changed");
        _tokenUri = newUri;
    }
    
    function lockContract() public onlyOwner {
        contractLocked = true;   
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

    /** OVERRIDES */
    function _baseURI() internal view override returns (string memory) {
        return _tokenUri;
    }
    
	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}