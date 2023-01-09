// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./Ownable.sol";
import "./Nameable.sol";
import { DEFAULT, FLAG, PRE, SetFlexibleMetadata, FlexibleMetadataData } from "./SetFlexibleMetadata.sol";

abstract contract FlexibleMetadata is Ownable, Context, ERC165, IERC721, Nameable {  
    using SetFlexibleMetadata for FlexibleMetadataData;
    FlexibleMetadataData flexible;   

    constructor(string memory _name, string memory _symbol) Nameable(_name,_symbol) {
    }   
    
    function setContractUri(string memory uri) public onlyOwner {
        flexible.setContractMetadataURI(uri);
    }

    function reveal(bool _reveal) public onlyOwner {
        flexible.reveal(_reveal);
    }

    function setTokenUri(string memory uri, uint256 tokenType) public {
        tokenType == FLAG ?
            flexible.setFlaggedTokenMetadataURI(uri):
            (tokenType == PRE) ?
                flexible.setPrerevealTokenMetadataURI(uri):
                    flexible.setDefaultTokenMetadataURI(uri);
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
    function contractURI() public view returns (string memory) {
        return flexible.getContractMetadata();
    }    
}