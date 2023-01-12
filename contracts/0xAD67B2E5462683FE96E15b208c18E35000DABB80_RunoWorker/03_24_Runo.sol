// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

import { IReward } from "../interface/IReward.sol";
import { IRuno } from "../interface/IRuno.sol";
import "../types/Type.sol";

contract Runo is DefaultOperatorFilterer,
  ERC721Enumerable, ERC2981, AccessControl {
  // makes uint256 variable can call up functions in the Strings library
  using Strings for uint256;
  using Counters for Counters.Counter;

  string public baseUri;
  address private _owner;
  uint256 public totalSupplyCap;
  uint256[] public rewardFactorByTier;
  address public rewardContract;

  /**
   * Token & Tier information
   * Token IDs of tier x => tierMaxCap*x + 1 ~ tierMaxCap*x + tierSupplyCap[x]
   */
  uint256 maxTier;
  mapping(uint256 => uint256) public minTokenIds;
  mapping(uint256 => uint256) public tierSupplyCap;
  mapping(uint256 => Counters.Counter) public currentTierTokenId;
  mapping(uint256 => bool) public isRunning;

  // Constants
  uint256 public constant tierMaxCap = 100000;
  bytes32 public constant OWNER_ROLE = keccak256("OWNER");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER");
  bytes32 public constant REWARD_ROLE = keccak256("REWARD");
  uint256 public constant TOKEN_FETCH_LIMIT = 100;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseUri_
  ) ERC721(name_, symbol_) {
    _owner = _msgSender();
    _grantRole(OWNER_ROLE, _msgSender());
    _grantRole(MINTER_ROLE, _msgSender());
    _setRoleAdmin(MINTER_ROLE, OWNER_ROLE);
    _setRoleAdmin(REWARD_ROLE, OWNER_ROLE);

    baseUri = baseUri_;
  }

  function supportsInterface(
    bytes4 interfaceId_
  ) public view override(
    ERC721Enumerable,
    ERC2981,
    AccessControl
  ) returns (bool) {
    return interfaceId_ == type(IRuno).interfaceId ||
        super.supportsInterface(interfaceId_);
  }

  /**
   * @dev Required to be recognized as the owner of the collection on OpenSea.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Returns the URI of the token with tokenId.
   * @param tokenId_ ID of token
   */
  function tokenURI(
    uint256 tokenId_
  ) public view override returns (string memory) {
    require(_exists(tokenId_), "Runo: non-exist token ID");
    return string(abi.encodePacked(baseUri, tokenId_.toString()));
  }

  /**
   * @dev Returns a list of token IDs owned by user.
   * @param owner_ address of token owner
   * @param offset_ index offset
   * @param limit_ max number of IDs to fetch
   * @return tokenIds ID of tokens
   */
  function tokensOf(
    address owner_,
    uint256 offset_,
    uint256 limit_
  ) public view returns (uint256[] memory) {
    uint256 balance = ERC721.balanceOf(owner_);
    require(0 < limit_ && limit_ <= TOKEN_FETCH_LIMIT, "Runo: limit too large");
    require(offset_ < balance || balance == 0, "Runo: invalid offset");

    uint256 numToReturn = balance == 0 ? 0 :
      ((offset_ + limit_ <= balance) ? limit_ : balance - offset_);
    uint256[] memory tokenIds = new uint256[](numToReturn);
    for (uint256 i = 0; i < numToReturn; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(owner_, offset_ + i);
    }
    return tokenIds;
  }

  /**
   * @dev Returns information of a Runo NFT
   * @param tokenId_ ID of the Runo NFT
   */
  function getTokenTier(
    uint256 tokenId_
  ) public view returns (uint256) {
    require(_exists(tokenId_), "Runo: tokenId not exists");
    return (tokenId_ - 1) / tierMaxCap;
  }

  /**
   * @dev Returns a max tier of token
   */
  function getMaxTier(
  ) public view returns (uint256) {
    return maxTier;
  }

  /**
   * @dev Returns a tier info
   * @param tier_ tier of Runo NFT
   */
  function getTierInfo(
    uint256 tier_
  ) public view returns (TierInfo memory) {
    require(0 <= tier_ && tier_ <= maxTier, "Runo: invalid tier");
    return TierInfo({
        totalSupply: tierSupplyCap[tier_],
        currentSupply: currentTierTokenId[tier_].current(),
        minTokenId: minTokenIds[tier_]
      });
  }

  /**
   * @dev Get list of running tokens
   * @param offset_ index offset
   * @param limit_ max number of IDs to fetch
   * @return length length of returned array
   * @return tokenIds array of IDs
   * @return state array of token state
   * @return ownerAddrs array of owner ethereum address
   */
  function getMintedTokenList(
    uint256 offset_,
    uint256 limit_
  ) public view returns (
    uint256,
    uint256[] memory,
    bool[] memory,
    address[] memory
  ) {
    require(0 < limit_ && limit_ <= TOKEN_FETCH_LIMIT, "Runo: limit too large");
    uint256 total = totalSupply();
    require(offset_ < total || total == 0, "Runo: invalid offset");
    uint256 numToReturn = total == 0 ? 0 : 
      ((offset_ + limit_ <= total) ? limit_ : total - offset_);
    uint256[] memory tokenIds = new uint256[](numToReturn);
    bool[] memory running = new bool[](numToReturn);
    address[] memory ownerAddrs = new address[](numToReturn);
    for (uint256 i = 0; i < numToReturn; i++) {
      tokenIds[i] = tokenByIndex(offset_ + i);
      running[i] = isTokenRunning(tokenIds[i]);
      ownerAddrs[i] = ownerOf(tokenIds[i]);
    }

    return (total, tokenIds, running, ownerAddrs);
  }

  function isTokenRunning(
    uint256 tokenId_
  ) public view returns (bool) {
    return isRunning[tokenId_];
  }

  function toggleRunning(
    uint256 tokenId_
  ) public onlyRole(REWARD_ROLE) {
    isRunning[tokenId_] = !isRunning[tokenId_];
  }

  /**
   * @dev Mint a token with a tier 
   * @param to_ address of user who purchases token
   * @param tier_ tier of token purchased
   */
  function mint(
    address to_,
    uint256 tier_
  ) public virtual onlyRole(MINTER_ROLE) returns (uint256) {
    require(0 <= tier_ && tier_ <= maxTier, "Runo: invalid tier");
    require(currentTierTokenId[tier_].current() < tierSupplyCap[tier_],
      "Runo: max tier supply reached");

    uint256 newTokenId = minTokenIds[tier_] + currentTierTokenId[tier_].current();
    currentTierTokenId[tier_].increment();

    // https://blocksecteam.medium.com/when-safemint-becomes-unsafe-lessons-from-the-hypebears-security-incident-2965209bda2a
    _safeMint(to_, newTokenId);

    return newTokenId;
  }

  /**
   * @dev Burn a Runo with token ID
   * @param tokenId_ tier of token purchased
   */
  function burn(
    uint256 tokenId_
  ) public virtual onlyRole(OWNER_ROLE) {
    // XXX only OWENR can burn?
    require(!isRunning[tokenId_], "Runo: not in burnable state");
    _burn(tokenId_);
  }

  /**
   * @dev Update base URI 
   * @param baseUri_ new token base URI
   */
  function updateBaseUri(
    string memory baseUri_
  ) public onlyRole(OWNER_ROLE) {
    baseUri = baseUri_;
  }

  /**
   * @dev Update supply cap of specific tier
   * @param tier_ tier of Runo NFT
   * @param cap_ new cap for tier
   */
  function updateTierCap(
    uint256 tier_,
    uint256 cap_
  ) public onlyRole(OWNER_ROLE) {
    require(0 <= tier_ && tier_ <= maxTier, "Runo: invalid tier");
    require(0 < cap_ && cap_ <= tierMaxCap, "Runo: invalid cap");
    totalSupplyCap -= tierSupplyCap[tier_];
    tierSupplyCap[tier_] = cap_;
    totalSupplyCap += cap_;
  }

  /**
   * @dev Set royalty info
   * @param beneficiary_ address who gets royalty
   * @param feeNumerator_ numerator (denominator is 10,000)
   */
  function setDefaultRoyalty(
    address beneficiary_,
    uint96 feeNumerator_
  ) public onlyRole(OWNER_ROLE) {
    _setDefaultRoyalty(beneficiary_, feeNumerator_);
  }
  
  function getRewardContractAddress(
  ) public view returns (address) {
    return rewardContract;
  }

  function setRewardContractAddress(
    address rewardContract_
  ) public onlyRole(OWNER_ROLE) {
    rewardContract = rewardContract_;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    require(!isRunning[tokenId], "Runo: not in transferable state");
    IReward(rewardContract).initClaimed(tokenId);
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /* for opensea creator fee supports */
  function setApprovalForAll(
    address operator, bool approved
  ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator, uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from, address to, uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from, address to, uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from, address to, uint256 tokenId, bytes memory data
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  /**
   * @dev Destruct contract 
   * @param to_ address who get contract's funds
   */
  function destroy(
    address payable to_
  ) public onlyRole(OWNER_ROLE) {
    selfdestruct(to_);
  }
}