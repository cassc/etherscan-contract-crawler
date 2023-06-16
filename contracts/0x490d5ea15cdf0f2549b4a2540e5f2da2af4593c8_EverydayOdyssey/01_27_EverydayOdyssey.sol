// SPDX-License-Identifier: GPL-3.0
// presented by Wildxyz

pragma solidity ^0.8.17;

import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {WildNFT} from '../common/WildNFT.sol';
import {DateTime} from './DateTime.sol';

import {EverydayOdysseyMetadata} from './EverydayOdysseyMetadata.sol';

contract EverydayOdyssey is WildNFT, DateTime {

    EverydayOdysseyMetadata public metadataContract;

    string private baseAnimationURI = 'https://test-static.wild.xyz/tokens/1130/html/index.html?tokenId=';

    constructor(address _minter, uint256 _maxSupply, string memory _baseURI, address[] memory _payees, uint256[] memory _shares, uint96 _feeNumerator ) WildNFT('Everyday Odyssey', 'EVERYDAYODYSSEY', _minter, _maxSupply, _baseURI, _payees, _shares, _feeNumerator) {}

    function setMetadataContract(EverydayOdysseyMetadata _metadataContract) public onlyOwner {
        metadataContract = _metadataContract;
    }

    function setBaseAnimationURI(string memory _baseAnimationURI) public onlyOwner {
        baseAnimationURI = _baseAnimationURI;
    }

    // update 2981 royalty
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // tokenURI function returns json metadata for the token
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'Token does not exist.');
        return metadataContract.generateTokenURI(tokenId, baseURI, baseAnimationURI);
    }

}