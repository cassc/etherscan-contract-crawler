// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/v4/access/Ownable.sol";
import "@openzeppelin/contracts/v4/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/v4/access/AccessControl.sol";
import "@openzeppelin/contracts/v4/utils/Counters.sol";

contract NFTSport is ERC721, Ownable, AccessControl {
  using Counters for Counters.Counter;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  uint256 public constant NUMBER_OF_TEAMS = 32;

  Counters.Counter private _tokenIds;
  mapping(uint256 => uint256) public nftToTeam;

  // Base URI
  string public baseURI;

  constructor() ERC721("NFT Sport", "NFTSport") {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _tokenIds.increment();
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  function mint(address account, uint256 teamId) external returns (uint256) {
    require(hasRole(MINTER_ROLE, _msgSender()), "mint: only MINTER_ROLE");
    require(teamId < NUMBER_OF_TEAMS, "mint: invalid teamId");
    uint256 tokenId = _tokenIds.current();
    _safeMint(account, tokenId);
    _tokenIds.increment();
    nftToTeam[tokenId] = teamId;
    return tokenId;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}