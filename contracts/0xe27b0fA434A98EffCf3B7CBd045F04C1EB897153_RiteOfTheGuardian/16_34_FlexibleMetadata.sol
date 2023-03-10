// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./Ownable.sol";
import "./Nameable.sol";
import { DEFAULT, FLAG, PRE, Supplement, SetFlexibleMetadata, FlexibleMetadataData } from "./SetFlexibleMetadata.sol";

abstract contract FlexibleMetadata is Ownable, Context, ERC165, IERC721, Nameable {  
    using SetFlexibleMetadata for FlexibleMetadataData;
    FlexibleMetadataData flexible;   

    constructor(string memory _name, string memory _symbol) Nameable(_name,_symbol) {
    }   
    
    function setContractUri(string memory uri) external onlyOwner {
        flexible.setContractMetadataURI(uri);
    }

    function reveal(bool _reveal) external onlyOwner {
        flexible.reveal(_reveal);
    }

    function setTokenUri(string memory uri, uint256 tokenType) external onlyOwner {
        tokenType == FLAG ?
            flexible.setFlaggedTokenMetadataURI(uri):
            (tokenType == PRE) ?
                flexible.setPrerevealTokenMetadataURI(uri):
                    flexible.setDefaultTokenMetadataURI(uri);
    }

    function setSupplementalTokenUri(uint256 key, string memory uri) external onlyOwner {
        flexible.setSupplementalTokenMetadataURI(key,uri);
    }

    function flagToken(uint256 tokenId, bool isFlagged) external onlyOwner {
        flexible.flagToken(tokenId,isFlagged);
    }

    function setSupplemental(uint256 tokenId, bool isSupplemental, uint256 key) internal {
        if (isSupplemental) {
            flexible.supplemental[tokenId] = Supplement(key,true);
        } else {
            delete flexible.supplemental[tokenId];
        }
    }    

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165,IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }   

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {        
        return flexible.getTokenMetadata(tokenId);
    }          
    function contractURI() external view returns (string memory) {
        return flexible.getContractMetadata();
    }    
}