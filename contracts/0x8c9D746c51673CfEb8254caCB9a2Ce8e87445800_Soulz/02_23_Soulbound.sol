// SPDX-License-Identifier: MIT

/// @author notu @notuart

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import './interfaces/ISoulz.sol';
import './interfaces/ITrustee.sol';

contract Soulbound is ERC721Enumerable, Ownable {
  /// Trustee contract can read various bonds between souls
  ITrustee public trustee;

  /// Mapping from tokenId to lock state. Tokens are locked upon minting.
  mapping(uint256 => bool) public locked;

  /// Mapping from tokenId to backup address
  mapping(uint256 => address) public backup;

  /// Mapping from tokenId to transfer requests from trustee Id
  mapping(uint256 => uint256[]) public requests;

  /// Mapping from owner address to token ID
  mapping(address => uint256) public souls;

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

  /// Retrieve the token ID owned by a given address
  function soulOf(address wallet) public view returns (uint256) {
    return souls[wallet];
  }

  /// Attach a wallet to a token ID
  function _bind(address wallet, uint256 tokenId) internal {
    souls[wallet] = tokenId;
  }

  /// Breaks the link to the soul
  function _release(address wallet) internal {
    delete souls[wallet];
  }

  /// Locks the asset which becomes no transferrable
  function _lock(uint256 tokenId) internal {
    locked[tokenId] = true;
  }

  /// The key to the soulbound contract
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    if (to != address(0)) {
      require(locked[tokenId] == false, 'Soulbound: transfer is locked');
      require(balanceOf(to) == 0, 'Soulbound: one per wallet');
    }

    super._beforeTokenTransfer(from, to, tokenId);

    _lock(tokenId);
    _release(from);
    _bind(to, tokenId);

    delete backup[tokenId];
    delete requests[tokenId];
  }

  function setTrusteeContract(address trusteeContractAddress) public onlyOwner {
    trustee = ITrustee(trusteeContractAddress);
  }

  function setBackupAddress(address backupAddress, uint256 tokenId) public {
    require(ownerOf(tokenId) == msg.sender, 'Soulbound: wrong owner');
    require(
      backup[tokenId] == address(0),
      'Soulbound: backup address can only be set once'
    );
    require(
      balanceOf(backupAddress) == 0,
      'Soulbound: backup address should be soulless'
    );

    backup[tokenId] = backupAddress;
  }

  function requestCount(uint256 tokenId) public view returns (uint256) {
    return requests[tokenId].length;
  }

  function requestTransfer(uint256 tokenId, uint256 trusteeId) public {
    require(
      address(trustee) != address(0),
      'Soulbound: trustee contract not set'
    );
    require(
      tokenId != trusteeId,
      'Soulbound: cannot request transfer for same token ID'
    );
    require(_exists(tokenId), 'Soulbound: invalid token ID');
    require(_exists(trusteeId), 'Soulbound: invalid trustee token ID');
    require(
      ownerOf(tokenId) != msg.sender,
      'Soulbound: wrong owner for token ID'
    );
    require(
      ownerOf(trusteeId) == msg.sender,
      'Soulbound: wrong owner for trustee token ID'
    );
    require(backup[tokenId] != address(0), 'Soulbound: backup wallet not set');
    require(
      trustee.trust(tokenId, trusteeId),
      'Soulbound: trust cannot be established'
    );

    requests[tokenId].push(trusteeId);

    if (requestCount(tokenId) == 3) {
      locked[tokenId] = false;
      _transfer(ownerOf(tokenId), backup[tokenId], tokenId);
      _bind(backup[tokenId], tokenId);
    }
  }

  function burn(uint256 tokenId) public {
    require(
      ownerOf(tokenId) == msg.sender,
      'Soulbound: caller is not token owner'
    );

    locked[tokenId] = true;

    delete backup[tokenId];
    delete requests[tokenId];

    _burn(tokenId);
  }
}