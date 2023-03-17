// SPDX-License-Identifier: UNLICENSED
// AINFT Contracts v1.1.0
pragma solidity ^0.8.9;

import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';
import '../interfaces/IAINFTBaseV1.sol';

/**
 * @title AINFTBaseV1
 * @dev [ERC721](https://eips.ethereum.org/EIPS/eip-721) compliant.
 * @notice
 * - v1.0.0: supports tokensOf method, which returns the owner's token ID.
 * - v1.1.0: supports transfer and approval methods for allowed operators.
 */
abstract contract AINFTBaseV1 is
  ERC721Enumerable,
  ERC721Burnable,
  Ownable,
  AccessControl,
  DefaultOperatorFilterer
{
  using Strings for uint256;

  error InvalidLimit(uint256 limit, uint8 tokenFetchLimit);
  error InvalidOffset(uint256 offset, uint256 balance);

  bytes32 public constant OWNER_ROLE = keccak256('OWNER');
  bytes32 public constant MINTER_ROLE = keccak256('MINTER');
  uint256 public nextTokenId = 1;
  uint256 public maxTokenId;
  uint8 public constant MAX_MINT_QUANTITY = 100;
  uint8 public constant TOKEN_FETCH_LIMIT = 100;
  string public baseURI = '';

  event Mint(
    address indexed to,
    uint256 indexed startTokenId,
    uint256 quantity
  );

  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseURI_,
    uint256 maxTokenId_
  ) ERC721(name_, symbol_) {
    require(bytes(baseURI_).length > 0, 'AINFTv1: invalid baseURI_');
    require(maxTokenId_ > 0, 'AINFTv1: invalid maxTokenId_');

    _grantRole(OWNER_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _setRoleAdmin(MINTER_ROLE, OWNER_ROLE);

    baseURI = baseURI_;
    maxTokenId = maxTokenId_;
  }

  // ============= QUERY

  function supportsInterface(bytes4 interfaceId_)
    public
    view
    virtual
    override(AccessControl, ERC721, ERC721Enumerable)
    returns (bool)
  {
    return
      type(IAINFTBaseV1).interfaceId == interfaceId_ ||
      super.supportsInterface(interfaceId_);
  }

  function tokenURI(uint256 tokenId_)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId_), 'AINFTv1: URI query for nonexistent token');
    require(bytes(baseURI).length > 0, 'AINFTv1: invalid baseURI');

    return string(abi.encodePacked(baseURI, tokenId_.toString()));
  }

  /**
   * @dev Returns the token IDs of the owner, starting at the `offset_` ending at `offset_ + limit_ - 1`
   * @param owner_ address of the owner
   * @param offset_ index offset to start enumerating within the ownedTokens list of the owner
   * @param limit_ max number of IDs to fetch
   */
  function tokensOf(
    address owner_,
    uint256 offset_,
    uint256 limit_
  ) public view returns (uint256[] memory) {
    uint256 balance = ERC721.balanceOf(owner_);
    if (limit_ == 0 || limit_ > TOKEN_FETCH_LIMIT) {
      revert InvalidLimit(limit_, TOKEN_FETCH_LIMIT);
    }
    if (offset_ >= balance) {
      revert InvalidOffset(offset_, balance);
    }

    uint256 numToReturn = (offset_ + limit_ <= balance)
      ? limit_
      : balance - offset_;
    uint256[] memory ownedTokens = new uint256[](numToReturn);
    for (uint256 i = 0; i < numToReturn; i++) {
      ownedTokens[i] = tokenOfOwnerByIndex(owner_, offset_ + i);
    }
    return ownedTokens;
  }

  // ============= TX

  function setBaseURI(string calldata baseURI_) public onlyRole(OWNER_ROLE) {
    require(bytes(baseURI_).length > 0, 'AINFTv1: invalid baseURI_');
    baseURI = baseURI_;
  }

  function setMaxTokenId(uint256 maxTokenId_) public onlyRole(OWNER_ROLE) {
    require(nextTokenId - 1 <= maxTokenId_, 'AINFTv1: invalid maxTokenId_');
    maxTokenId = maxTokenId_;
  }

  function mint(address to_, uint8 quantity_)
    public
    virtual
    onlyRole(MINTER_ROLE)
    returns (uint256)
  {
    require(to_ != address(0), 'AINFTv1: invalid to_ address');
    require(
      0 < quantity_ && quantity_ <= MAX_MINT_QUANTITY,
      'AINFTv1: invalid quantity_'
    );
    require(
      nextTokenId + quantity_ - 1 <= maxTokenId,
      'AINFTv1: exceeds maxTokenId'
    );

    uint256 startTokenId = nextTokenId;
    for (uint8 i = 0; i < quantity_; i++) {
      _safeMint(to_, nextTokenId);
      nextTokenId += 1;
    }
    emit Mint(to_, startTokenId, quantity_);

    return startTokenId;
  }

  function burn(uint256 tokenId_) public virtual override onlyRole(OWNER_ROLE) {
    _burn(tokenId_);
  }

  function destroy(address payable to_) public onlyRole(OWNER_ROLE) {
    require(to_ != address(0), 'AINFTv1: invalid to_ address');
    selfdestruct(to_);
  }

  // ============= OPENSEA REGISTRY

  function setApprovalForAll(address operator, bool approved)
    public
    override(ERC721, IERC721)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId)
    public
    override(ERC721, IERC721)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  // ============= HOOKS

  function _beforeTokenTransfer(
    address from_,
    address to_,
    uint256 tokenId_
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from_, to_, tokenId_);
  }
}