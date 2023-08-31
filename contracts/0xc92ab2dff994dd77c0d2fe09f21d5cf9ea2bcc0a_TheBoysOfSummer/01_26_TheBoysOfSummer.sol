// SPDX-License-Identifier: GPL-3.0-or-later

// The Boys of Summer - by Mitchell F Chan
// Presented by Wildxyz

pragma solidity ^0.8.17;

import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import {WildNFT} from '../common/WildNFT.sol';

contract TheBoysOfSummer is WildNFT {
  string public attributeURI;

  constructor(address _minter, uint256 _maxSupply, string memory _baseURI, address[] memory _payees, uint256[] memory _shares, uint96 _feeNumerator) WildNFT('The Boys of Summer', 'THEBOYSOFSUMMER', _minter, _maxSupply, _baseURI, _payees, _shares, _feeNumerator) {}

  function setImmutableAttributeURI(string memory _attributeURI) public onlyOwner {
    attributeURI = _attributeURI;
  }

  function immutableAttributeURI(uint256 _tokenId) public view returns (string memory) {
    require(_exists(_tokenId), 'Token does not exist.');
    return string(abi.encodePacked(attributeURI, Strings.toString(_tokenId), '.json'));
  }

  // update 2981 royalty
  function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), 'Token does not exist.');
    return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), '.json'));
  }
}