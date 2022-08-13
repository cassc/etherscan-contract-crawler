// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TDGenerativemasks is ERC721, Ownable {

    using Strings for uint256;
    
    string private __baseURI;
    uint256 public constant METADATA_INDEX = 3799; 
    address public constant GENERATIVEMASKS = 0x80416304142Fa37929f8A4Eee83eE7D2dAc12D7c; 
    bool public isMetadataFrozen;
    bool public isMintingFrozen;

    constructor(string memory initialBaseURI) ERC721("3D Generativemasks", "3DGM") {
        __baseURI = initialBaseURI; 
    }

    function _baseURI() internal view override returns(string memory) { 
        return __baseURI; 
    }

    function mintBatch(
        address[] memory toList,
        uint256[] memory tokenIdList
    ) external onlyOwner {
        require(!isMintingFrozen, "TDGenerativemasks: Minting is frozen");
        require(toList.length == tokenIdList.length, "TDGenerativemasks: Arguments length are not matched");
        for (uint256 i; i < toList.length; i++) {
            _mint(toList[i], tokenIdList[i]);
        }
    }

    function updateBaseURI(string calldata newBaseURI) external onlyOwner {
        require(!isMetadataFrozen, "TDGenerativemasks: Metadata is already frozen");
        __baseURI = newBaseURI;
    }

    function freezeMetadata() external onlyOwner { 
        require(!isMetadataFrozen, "TDGenerativemasks: Metadata is already frozen");
        isMetadataFrozen = true;
    }

    function freezeMinting() external onlyOwner { 
        require(!isMintingFrozen, "TDGenerativemasks: Minting is already frozen");
        isMintingFrozen = true;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "TDGenerativemasks: URI query for nonexistent token");

        uint256 metadataId = (tokenId + METADATA_INDEX) % 10000;
        return string(abi.encodePacked(__baseURI, metadataId.toString(), ".json"));
    }
}