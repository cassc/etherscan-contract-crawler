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

abstract contract skinTokenContract {
    function skinUnequipped(uint256 tokenId, address owner) public virtual;
    function mint(address receiver) public virtual returns(uint256);
}

abstract contract newMnlthTokenContract {
    function mint(address receiver) public virtual returns(uint256);
}


contract MNLTHRVLD is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MNLTHRVLD", "MNLTHRVLD") {
        _tokenIdCounter.increment(); // Making sure we start at token ID 1
    }
    
    string public _tokenUri = ""; // Initial base URI
    address mnlthAddress = 0x5e0e691778e2061ecf56a58cf4D3466d19CF7389;
    address vialAddress = 0x0f666172E2AB3dE7692e118482e11e348B476A8a;
    address newmnlthAddress = 0x9dE9a9bA469e3627e3d08D7B9798f3B64eA08A4f;

    mapping (uint256 => uint256) public equippedSkin;
    
    bool public contractLocked = false;

    function mintTransfer(address to) public returns(uint256) {
        require(msg.sender == mnlthAddress, "Not authorized");
        
        uint256 mintedId =  _tokenIdCounter.current();

        // D
        _safeMint(to, _tokenIdCounter.current());
        _setTokenURI(_tokenIdCounter.current(), "https://mnlthassets.rtfkt.com/dunks/0");
        _tokenIdCounter.increment();

        // V
        skinTokenContract vialContract = skinTokenContract(vialAddress);
        uint256 vialId = vialContract.mint(to); 
        
        // // M
        newMnlthTokenContract newMnlthContract = newMnlthTokenContract(newmnlthAddress);
        uint256 mnlthId = newMnlthContract.mint(to); 

        return mintedId;
    }
    
    // Change the MNLTH address contract
    function setMnlthAddress(address newAddress) public onlyOwner { 
        mnlthAddress = newAddress;
    }

    // Change the VIAL address contract
    function setVialAddress(address newAddress) public onlyOwner { 
        vialAddress = newAddress;
    }

    // Change the NMNLTH address contract
    function setNewMnlthAddress(address newAddress) public onlyOwner { 
        newmnlthAddress = newAddress;
    }
    
    function secureBaseUri(string memory newUri) public onlyOwner {
        require(contractLocked == false, "Contract has been locked and URI can't be changed");
        _tokenUri = newUri;
    }
    
    function lockContract() public onlyOwner {
        contractLocked = true;   
    }

    function equipSkin(uint256 dunkId, uint256 vialId) public {
        require(msg.sender == vialAddress, "Not authorized");
        require(equippedSkin[dunkId] == 0, "A skin is already equipped");
        equippedSkin[dunkId] = vialId;
        _setTokenURI(dunkId, string(abi.encodePacked("https://mnlthassets.rtfkt.com/dunks/", uint2str(vialId))));
    }

    function unequipSkin(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You don't own that token");
        require(equippedSkin[tokenId] != 0, "No skin equipped");

        skinTokenContract vialContract = skinTokenContract(vialAddress);
        vialContract.skinUnequipped(equippedSkin[tokenId], msg.sender); 
        equippedSkin[tokenId] = 0;
        _setTokenURI(tokenId, "https://mnlthassets.rtfkt.com/dunks/0"); 
    }

    function getEquippedSkin(uint256 dunkId) public view returns(uint256) {
        return equippedSkin[dunkId];
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

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}