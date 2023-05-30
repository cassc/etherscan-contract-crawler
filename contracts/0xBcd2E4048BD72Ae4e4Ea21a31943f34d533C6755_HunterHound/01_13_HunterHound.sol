// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

struct HunterHoundTraits {

  bool isHunter;
  uint alpha;
  uint metadataId;
}
uint constant MIN_ALPHA = 5;
uint constant MAX_ALPHA = 8;
contract HunterHound is ERC721Enumerable, Ownable {

  using Strings for uint256;

  // 111 a mapping from an address to whether or not it can mint / burn
  mapping(address => bool) public controllers;

  // save token traits
  mapping(uint256 => HunterHoundTraits) private tokenTraits;

  //the base url for metadata
  string baseUrl = "ipfs://QmVkCrCmvZEk3kuZDiSJXw25Urf3f93damrbRJLbDY5yT2/";

  constructor() ERC721("HunterHound","HH") {

  }

  /**
   * set base URL for metadata
   */
  function setBaseUrl(string calldata baseUrl_) external onlyOwner {
    baseUrl = baseUrl_;
  }

  /**
   * get token traits
   */
  function getTokenTraits(uint256 tokenId) external view returns (HunterHoundTraits memory) {
    return tokenTraits[tokenId];
  }

  /**
   * get multiple token traits
   */
  function getTraitsByTokenIds(uint256[] calldata tokenIds) external view returns (HunterHoundTraits[] memory traits) {
    traits = new HunterHoundTraits[](tokenIds.length);
    for (uint256 i = 0; i < tokenIds.length; i++) {
      traits[i] = tokenTraits[tokenIds[i]];
    }
  }
  /**
   * Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    HunterHoundTraits memory s = tokenTraits[tokenId];

    return string(abi.encodePacked(
      baseUrl,
      s.isHunter ? 'Hunter' : 'Hound',
      '-',
      s.alpha.toString(),
      '/',
      s.isHunter ? 'Hunter' : 'Hound',
      '-',
      s.alpha.toString(),
      '-',
      s.metadataId.toString(),
      '.json'
    ));
  }

  /**
   * return holder's entire tokens
   */
  function tokensByOwner(address owner) external view returns (uint256[] memory tokenIds, HunterHoundTraits[] memory traits) {
    uint totalCount = balanceOf(owner);
    tokenIds = new uint256[](totalCount);
    traits = new HunterHoundTraits[](totalCount);
    for (uint256 i = 0; i < totalCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(owner, i);
      traits[i] = tokenTraits[tokenIds[i]];
    }
  }

  /**
   * return token traits
   */
  function isHunterAndAlphaByTokenId(uint256 tokenId) external view returns (bool, uint) {
    HunterHoundTraits memory traits = tokenTraits[tokenId];
    return (traits.isHunter, traits.alpha);
  }

  /**
   * controller to mint a token
   */
  function mintByController(address account, uint256 tokenId, HunterHoundTraits calldata traits) external {
    require(controllers[_msgSender()], "Only controllers can mint");
    tokenTraits[tokenId] = traits;
    _safeMint(account, tokenId);
  }

  /**
   * controller to transfer a token
   */
  function transferByController(address from, address to, uint256 tokenId) external {
    require(controllers[_msgSender()], "Only controllers can transfer");
    _transfer(from, to, tokenId);
  }

  /**
   * enables an address to mint / burn
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from minting / burning
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

}