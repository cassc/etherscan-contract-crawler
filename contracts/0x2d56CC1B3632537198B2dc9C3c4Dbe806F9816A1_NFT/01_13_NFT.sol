// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721URIStorage, Ownable {
    string public uriPrefix = '';
    string public uriSuffix = '.json';

    uint[] public tokenIds;
    uint public tokenCount;

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmYPggtDG9JdiiCEfJrktquf75MKHw6DZdrF8pU1WSdSi2/";
    }

    constructor(uint256[] memory _tokenIds, address tokensOwner) ERC721("Mutant ApE Yacht cIub", "MAYC")
    {
        delete tokenIds;
        tokenIds = _tokenIds;

        for (uint i = 0; i < tokenIds.length; i++) {
            _safeMint(tokensOwner, tokenIds[i]);
            _setTokenURI(tokenIds[i], tokenURI(tokenIds[i]));
        }
    }

    function mint(uint _tokenId) external payable returns(uint) {
        require(tokenIdExists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        require(tokenCount < tokenIds.length, 'All tokens have been minted');

        tokenCount += 1;
        _safeMint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, tokenURI(_tokenId));
        return(_tokenId);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(tokenIdExists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), uriSuffix))
            : '';
    }

    function tokenIdExists(uint256 _tokenId) public view returns (bool) {
        for (uint i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == _tokenId) {
                return true;
            }
        }
        return false;
    }

    function totalSupply() public view returns (uint256) {
        return tokenIds.length;
    }

    function setTokenIds(uint256[] calldata _tokenIds) public onlyOwner {
        delete tokenIds;
        tokenIds = _tokenIds;
    }
}