// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import './WhitelistTimelock.sol';

contract ASMBrain is ERC721Enumerable, WhitelistTimelock {
  using Address for address;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  uint256 public maxSupply;

  mapping(uint256 => string) public tokenHashes;

  event Minted(address minter, address recipient, string hash, uint256 tokenId);
  event MaxSupplyChanged(uint256 supply);

  constructor(uint256 initSupply) ERC721('ASMBrain', 'ASMBrain') {
    maxSupply = initSupply;
  }

  function mint(string calldata hash, address recipient)
    external
    onlyWhitelisted
  {
    require(
      _tokenIds.current() + 1 <= maxSupply,
      'Max supply of tokens exceeded.'
    );

    uint256 newItemId = _tokenIds.current();
    _safeMint(recipient, newItemId);
    _tokenIds.increment();

    tokenHashes[newItemId] = hash;

    emit Minted(msg.sender, recipient, hash, newItemId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), 'URI query for nonexistent token');

    string memory hash = tokenHashes[tokenId];
    return
      bytes(hash).length > 0 ? string(abi.encodePacked('ipfs://', hash)) : '';
  }

  function setMaxSupply(uint256 supply) external onlyWhitelisted {
    maxSupply = supply;
    emit MaxSupplyChanged(supply);
  }
}