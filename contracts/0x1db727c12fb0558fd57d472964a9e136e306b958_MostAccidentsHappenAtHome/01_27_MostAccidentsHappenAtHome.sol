// SPDX-License-Identifier: GPL-3.0
// presented by Wildxyz

pragma solidity ^0.8.17;

import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';

import {WildNFT} from '../common/WildNFT.sol';
import {MostAccidentsHappenAtHomeMetadata} from './MostAccidentsHappenAtHomeMetadata.sol';

contract MostAccidentsHappenAtHome is WildNFT {

    MostAccidentsHappenAtHomeMetadata public metadataContract;
    address public admin; // jonas lund address
    bool[256] public tokenToToppled; // tokenId to toppled
    string[256] public itemsDropped;
    uint[] public untoppledTokens;
    mapping (uint256 => string) public tokenToToppledURI;

    constructor(address _minter, uint256 _maxSupply, string memory _baseURI, address[] memory _payees, uint256[] memory _shares, uint96 _feeNumerator ) WildNFT('Most Accidents Happen At Home', 'MostAccidentsHappenAtHome', _minter, _maxSupply, _baseURI, _payees, _shares, _feeNumerator) {
        for (uint256 i = 0; i < 256; i++) {
            untoppledTokens.push(i);
        }
    }

    modifier onlyOwnerOrAdmin { 
        require(msg.sender == owner() || msg.sender == admin, 'Only owner or admin can call this function.');
        _; 
    }

    // ownerOrAdmin: set a specific tokenId to toppled
    function setTokenToToppled(uint256 _tokenId, bool _toppled, string calldata _item, string calldata _uri) public onlyOwnerOrAdmin {
        tokenToToppled[_tokenId] = _toppled;
        itemsDropped[_tokenId] = _item;
        tokenToToppledURI[_tokenId] = _uri;
        // emit metadata event
        emit MetadataUpdate(_tokenId);
    }

    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }

    function setMetadataContract(MostAccidentsHappenAtHomeMetadata _metadataContract) public onlyOwner {
        metadataContract = _metadataContract;
    }

    // update 2981 royalty
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // tokenURI function returns json metadata for the token
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'Token does not exist.');
        return metadataContract.generateTokenURI(tokenId, baseURI, tokenToToppledURI[tokenId], itemsDropped[tokenId], tokenToToppled[tokenId]);
    }

}