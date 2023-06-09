pragma solidity ^0.4.24;

import "./ERC721Token.sol";
import "./Registry.sol";
import "./DSAuth.sol";

/**
 * @title Token of a Meme. Single ERC721 instance represents all memes/cards
 */

contract MemeToken is ERC721Token {
  Registry public registry;

  modifier onlyRegistryEntry() {
    require(registry.isRegistryEntry(msg.sender),"MemeToken: onlyRegistryEntry failed");
    _;
  }

  function MemeToken(Registry _registry)
  ERC721Token("MemeToken", "MEME")
  {
    registry = _registry;
  }

  function mint(address _to, uint256 _tokenId)
  onlyRegistryEntry
  public
  {
    super._mint(_to, _tokenId);
    tokenURIs[_tokenId] = msg.sender;
  }

  function safeTransferFromMulti(
    address _from,
    address _to,
    uint256[] _tokenIds,
    bytes _data
  ) {
    for (uint i = 0; i < _tokenIds.length; i++) {
      safeTransferFrom(_from, _to, _tokenIds[i], _data);
    }
  }
}
