//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

interface INFT {
  function mintNEWELF(address to, uint tokenId) external;
  function exist(uint tokenId) external view returns (bool);
  function ownerOf(uint tokenId) external view returns (address);
  function transferFrom(address from, address to, uint id) external;
  function balanceOf(address owner) external view returns (uint256);
}

/// @author orion
contract NANOHUB is Ownable {
  INFT _ELFOOZ;
  INFT _NEWELF;

  constructor(address ELFOOZ, address NEWELF) {
    _ELFOOZ = INFT(ELFOOZ);
    _NEWELF = INFT(NEWELF);
  }

  function mintNEWELF(uint tokenId)
  public {
    require(!_NEWELF.exist(tokenId), "error NEWELF.exist");
    require(msg.sender == _ELFOOZ.ownerOf(tokenId), "error ELFOOZ.owner");
    _NEWELF.mintNEWELF(msg.sender, tokenId);
  }

  function batchMintNEWELF(uint256[] memory tokenIds)
  public {
    uint i = 0;
    uint balance = _ELFOOZ.balanceOf(msg.sender);
    require(balance == tokenIds.length, "error balance is invalid");
    while (i < balance) {
      uint tokenId = tokenIds[i];
      if (!_NEWELF.exist(tokenId)) {
        require(!_NEWELF.exist(tokenId), "error NEWELF.exist");
        require(msg.sender == _ELFOOZ.ownerOf(tokenId), "error ELFOOZ.owner");
        _NEWELF.mintNEWELF(msg.sender, tokenId);
      }
      i++;
    }
  }

  function recallNEWELF(uint tokenId)
  public {
    require(_NEWELF.exist(tokenId), "error NEWELF.exist");
    require(msg.sender != _NEWELF.ownerOf(tokenId), "error NEWELF.owner");
    require(msg.sender == _ELFOOZ.ownerOf(tokenId), "error ELFOOZ.owner");

    address newelfOwner = _NEWELF.ownerOf(tokenId);
    _NEWELF.transferFrom(newelfOwner, msg.sender, tokenId);
  }

  function batchRecallNEWELF(uint256[] memory tokenIds)
  public {
    uint i = 0;
    uint balance = _ELFOOZ.balanceOf(msg.sender);
    require(balance == tokenIds.length, "error balance is invalid");
    while (i < balance) {
      uint tokenId = tokenIds[i];
      require(msg.sender == _ELFOOZ.ownerOf(tokenId), "error ELFOOZ.owner");
      require(_NEWELF.exist(tokenId), "error NEWELF.exist");
      if (msg.sender != _NEWELF.ownerOf(tokenId)) {
        address newelfOwner = _NEWELF.ownerOf(tokenId);
        _NEWELF.transferFrom(newelfOwner, msg.sender, tokenId);
      }
      i++;
    }
  }

  function transferNEWELF(address to, uint tokenId)
  public {
    require(msg.sender == _NEWELF.ownerOf(tokenId), "error NEWELF.owner");
    require(_NEWELF.exist(tokenId), "error NEWELF.exist");

    _NEWELF.transferFrom(msg.sender, to, tokenId);
  }
}