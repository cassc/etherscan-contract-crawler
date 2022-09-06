// SPDX-License-Identifier: MIT
// Creator: Artur Chmaro for transparentworld.pl

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

contract TPBurner {
  address public tpContractAddr;

  uint public burnCount = 0;

  constructor(address _tpAddr) {
    tpContractAddr = _tpAddr;
  }

  function burnTp(uint [] calldata _tokenIds) public {
      for(uint i = 0; i < _tokenIds.length; i++) {
        IERC721(tpContractAddr).transferFrom(msg.sender, address(this), _tokenIds[i]);
      }

      burnCount += _tokenIds.length;
  }
}