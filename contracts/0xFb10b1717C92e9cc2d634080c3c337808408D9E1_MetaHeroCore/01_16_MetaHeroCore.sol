// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol';

/*
* @title ERC721 token for MetaHero core characters
*
* @author Niftydude
*/
contract MetaHeroCore is ERC721Enumerable, ERC721Burnable, Ownable {
    uint256 public constant MAX_SUPPLY = 146;   

    string private baseTokenURI;
    mapping(uint256 => string) private _tokenURIs;

    string public arweaveAssets;

    constructor (
        string memory _name, 
        string memory _symbol, 
        string memory _baseTokenURI
    ) ERC721(_name, _symbol) {
        baseTokenURI = _baseTokenURI;    
    }   

    /**
    * @notice Mint specified amount of MetaHero core tokens
    * 
    * @param amount the amount of MetaHero core tokens to mint
    */
    function mint(uint amount, string[] memory ipfsHashes) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Mint: max supply reached");
        require(amount == ipfsHashes.length, "Mint: ipfs hash needed for each token");

        for(uint i = 0; i < amount; i++) {
            uint256 tokenId = totalSupply() + 1;
            
            _mint(msg.sender, tokenId);
            _setTokenURI(tokenId, ipfsHashes[i]);
        }
    } 

    /**
    * @notice Update ipfs hash for specific tokens
    * 
    * @param indexes array containing all token ids to be updated
    * @param ipfsHashes array containing all new hashes
    */
    function updateIpfs(uint[] memory indexes, string[] memory ipfsHashes) external onlyOwner {
        require(indexes.length == ipfsHashes.length, "Update: ipfs hash needed for each token");

        for(uint i = 0; i < indexes.length; i++) {
            _setTokenURI(indexes[i], ipfsHashes[i]);
        }
    }

    /**
    * @notice Set pointer to arweave assets
    * 
    * @param _arweaveAssets pointer to images on Arweave network
    */
    function setArweaveAssets(string memory _arweaveAssets) external onlyOwner {
        arweaveAssets = _arweaveAssets;
    }          

    /**
    * @notice Update base URI
    * 
    * @param _baseTokenURI the new base URI
    */
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;    
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }       

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }    

    function _burn(uint256 tokenId) internal virtual override(ERC721) {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }   

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }     

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }   
}