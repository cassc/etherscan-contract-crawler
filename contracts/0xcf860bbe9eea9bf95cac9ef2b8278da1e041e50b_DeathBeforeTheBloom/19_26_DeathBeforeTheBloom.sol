// SPDX-License-Identifier: GPL-3.0
// presented by Wildxyz

pragma solidity ^0.8.17;

import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import {WildNFTRandom} from '../common/WildNFTRandom.sol';

contract DeathBeforeTheBloom is WildNFTRandom {
    constructor(address _minter, uint256 _maxSupply, string memory _baseURI, address[] memory _payees, uint256[] memory _shares, uint96 _feeNumerator) WildNFTRandom('Death Before the Bloom', 'DBTB', _minter, _maxSupply, _baseURI, _payees, _shares, _feeNumerator) {}

    // update 2981 royalty
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), 'Token does not exist.');
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), '.json'));
    }
}