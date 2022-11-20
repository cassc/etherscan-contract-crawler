// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title PLANT NFT contract
/// @author Rat Boi
/// @notice This contract is used to mint and interact with PLANT tokens
/// @dev This is a pretty standard ERC721 contract, but the mint method requires that tokens from the original SPYs contract be burned.
contract Plants is ERC721PausableUpgradeable, ERC721BurnableUpgradeable, ERC721RoyaltyUpgradeable, OwnableUpgradeable {
  using Counters for Counters.Counter;
  bool public revealed;
  uint8 public requiredSpys;
  uint16 private _requirementThreshold;
  uint16 private _tokenId;
  uint16 public maxTokens;
  uint private _launchTimestamp;
  string private baseURI;
  string private _contractUri;
  ERC721Burnable private _spysContract;
  function initialize(address spysContract, string memory initialBaseUri, string memory initialContractUri, address receiver, uint96 amount, uint16 threshold) initializer public {
    __Ownable_init();
    __ERC721Burnable_init_unchained();
    __ERC721Pausable_init_unchained();
    __ERC721Royalty_init_unchained();
    __ERC721_init("Plants", "PLNT");
    _requirementThreshold = threshold;
    revealed = false;
    _launchTimestamp = block.timestamp;
    maxTokens = 1000;
    requiredSpys = 3;
    _tokenId = 1;
    baseURI = initialBaseUri;
    _contractUri = initialContractUri;
    _spysContract = ERC721Burnable(spysContract);
    _setDefaultRoyalty(receiver, amount);
  }

  // Metadata
  function contractURI() public view returns(string memory) {
    return _contractUri;
  }

  function baseTokenURI() public view returns(string memory) {
    return baseURI;
  }

  function tokenURI(uint tokenId) public view override returns(string memory) {
    return string.concat(baseTokenURI(), Strings.toString(tokenId));
  }

  function reveal(string memory newBaseURI) public onlyOwner {
    require(!revealed, "Tokens already revealed");
    require(block.timestamp - _launchTimestamp >= 24 hours, "You must wait 24 hours before revealing");
    baseURI = newBaseURI;
    revealed = true;
  }

  function mint(uint[] memory tokenIds) public returns(uint) {
    require(_tokenId <= uint256(maxTokens), "Max tokens reached");
    require(
      tokenIds.length == requiredSpys,
      string.concat(string.concat(Strings.toString(tokenIds.length), " Spys tokens specified, but requires "), Strings.toString(requiredSpys))
    );
    bool approvedForAll = _spysContract.isApprovedForAll(_msgSender(), address(this));
    for (uint i = 0; i < tokenIds.length; i++) {
      uint tokenId = tokenIds[i];
      require(
        _spysContract.ownerOf(tokenId) == _msgSender(),
        string.concat("Sender does not own tokenId: ", Strings.toString(tokenId))
      );
      require(
        approvedForAll || _spysContract.getApproved(tokenId) == address(this),
        string.concat("Plants contract is not approved for tokenId: ", Strings.toString(tokenId))
      );
      _spysContract.burn(tokenId);
    }
    uint newTokenId = _tokenId;
    _safeMint(_msgSender(), newTokenId);
    if (newTokenId == _requirementThreshold) {
      requiredSpys = 4;
    }
    _tokenId++; 
    return newTokenId;
  }
  function batchMint(uint[][] memory tokenIds, uint tokensToMint) public returns (uint[] memory) {
    require(
      _tokenId + tokensToMint <= uint256(maxTokens),
      string.concat(
        string.concat(
          "Cannot mint ",
          Strings.toString(tokensToMint)
        ),
        string.concat(
          " tokens, only ",
          string.concat(
            Strings.toString(uint256(maxTokens) - _tokenId - 1),
            " tokens available"
          )
        )
      )
    );
    require(tokensToMint <= 10, "Cannot mint more than 10 tokens at a time");
    uint[] memory newTokens = new uint[](tokensToMint);
    for (uint8 i = 0; i < tokensToMint; i++) {
      newTokens[i] = mint(tokenIds[i]);
    }
    return newTokens;
  }

  function mintingOpen() public view returns (bool) {
    return _tokenId <= maxTokens;
  }

  // Required overrides for inherited contracts
  function _beforeTokenTransfer(address from, address to, uint tokenId, uint batchSize) internal override(ERC721Upgradeable, ERC721PausableUpgradeable) {
    return super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721RoyaltyUpgradeable) returns(bool) {
    return super.supportsInterface(interfaceId);
  }

  function _burn(uint tokenId) internal override(ERC721RoyaltyUpgradeable, ERC721Upgradeable) {
    super._burn(tokenId);
  }
}