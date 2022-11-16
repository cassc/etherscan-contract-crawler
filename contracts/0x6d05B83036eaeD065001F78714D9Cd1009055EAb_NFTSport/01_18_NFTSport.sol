// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../interfaces/INFTSport.sol";

contract NFTSport is INFTSport, ERC721, Ownable, AccessControl {
  using Counters for Counters.Counter;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  uint256 public constant NUMBER_OF_TEAMS = 32;

  Counters.Counter private _tokenIds;
  mapping(uint256 => uint256) public override nftToTeam;

  constructor() public ERC721("NFT Sport", "NFTSport") {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _tokenIds.increment();
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    _setBaseURI(baseURI);
  }

  function mint(address account, uint256 teamId) external override returns (uint256) {
    require(hasRole(MINTER_ROLE, _msgSender()), "mint: only MINTER_ROLE");
    require(teamId < NUMBER_OF_TEAMS, "mint: invalid teamId");
    uint256 tokenId = _tokenIds.current();
    _safeMint(account, tokenId);
    _tokenIds.increment();
    nftToTeam[tokenId] = teamId;
    return tokenId;
  }
}