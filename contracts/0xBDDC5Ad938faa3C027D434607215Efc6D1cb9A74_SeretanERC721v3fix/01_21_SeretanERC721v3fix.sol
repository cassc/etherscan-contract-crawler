// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./SeretanMintableFix.sol";
import "./SeretanERC2981.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract SeretanERC721v3fix is SeretanMintableFix, SeretanERC2981, UpdatableOperatorFilterer, ERC721Enumerable {
  string private baseURI;

  constructor(
    string memory name_,
    string memory symbol_,
    address registry_,
    address subscription_,
    uint96 feeNumerator_,
    address minter_,
    ISeretanMinter.Phase[] memory phaseList_,
    string memory baseURI_
  )
    ERC721(name_, symbol_)
    UpdatableOperatorFilterer(registry_, subscription_, true)
    SeretanERC2981(feeNumerator_)
    SeretanMintableFix(minter_, phaseList_)
  {
    baseURI = baseURI_;
  }

  function setApprovalForAll(
    address operator,
    bool approved
  )
    public
    override(ERC721, IERC721)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  )
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
  )
    public
    override(ERC721, IERC721)
    onlyAllowedOperator(from)
  {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
    override(ERC721, IERC721)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  )
    public
    override(ERC721, IERC721)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(
    string calldata baseURI_
  )
    public
    onlyOwner
  {
    _setBaseURI(baseURI_);
  }

  function _setBaseURI(
    string calldata baseURI_
  )
    internal
  {
    baseURI = baseURI_;
  }

  function _safeMint(
    address to,
    uint256 tokenId
  )
    internal
    override(ERC721, SeretanMintableFix)
  {
    super._safeMint(to, tokenId);
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(ERC721Enumerable, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function owner() public view override(Ownable, UpdatableOperatorFilterer, SeretanMintableFix) returns (address) {
    return super.owner();
  }
}