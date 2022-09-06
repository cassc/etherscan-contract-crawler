// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NjdaoToken is ERC721, ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;
  using Strings for uint256;

  Counters.Counter private _tokenIdCounter;

  mapping(address => bool) whitelist;
  mapping(uint256 => mapping(address => bytes32)) addressVerifyHash;
  mapping(uint256 => bool) tokenActive;
  string private uriPrefix;

  constructor(
    string memory _uriPrefix,
    address[] memory _whitelist
  ) ERC721(
    "NJORDAO",
    "NJO"
  ) {
    uriPrefix = _uriPrefix;
    for (uint i=0; i<_whitelist.length; i++) {
      whitelist[_whitelist[i]] = true;
    }
  }

  function activateToken(uint256 tokenId, bytes32 _hash, address _tokenOwner) public onlyOwner {
    require(
      addressVerifyHash[tokenId][_tokenOwner] == _hash,
      "Token not verified yet."
    );
    tokenActive[tokenId] = addressVerifyHash[tokenId][_tokenOwner] == _hash;
  }

  function submitVerifyHash(uint256 tokenId, bytes32 _hash) public {
    require(whitelist[msg.sender], "You are not authorised to submit the hash for verification.");
    addressVerifyHash[tokenId][msg.sender] = _hash;
  }
  
  function removeFromWhitelist(address _whitelistAddress) public onlyOwner {
    whitelist[_whitelistAddress] = false;
  }

  function addToWhitelist(address _whitelistAddress) public onlyOwner {
    whitelist[_whitelistAddress] = true;
  }

  function isAddressInWhitelist(address _whitelistAddress) view public returns (bool status) {
    return whitelist[_whitelistAddress];
  }

  function safeMint(address to) public onlyOwner {
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
  }

  // override the transferFrom to add the check that token
  // has been actived before transfer.
  function transferFrom( address from, address to, uint256 tokenId)
    override(ERC721)
    public 
  {
    require(
      tokenActive[tokenId] ||  msg.sender == owner(),
      "Token not activated, cannot transfer."
    );
    require(whitelist[to], "Address is not authorised to own token.");
    super.transferFrom(from, to, tokenId);
  }

  // The following functions are overrides required by Solidity.
  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    require(
      tokenId < _tokenIdCounter.current(),
      "Invalid Token Id."
    );
    return string(abi.encodePacked( uriPrefix, "rune-", tokenId.toString(), ".json"));
  }
}