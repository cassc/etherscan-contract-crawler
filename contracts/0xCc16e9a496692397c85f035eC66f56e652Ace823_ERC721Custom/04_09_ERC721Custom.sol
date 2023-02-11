// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract ERC721Custom is ERC721A, Ownable, DefaultOperatorFilterer {
  uint256 public maxSupply = 12;
  string public baseURI;

  event PermanentURI(string _value, uint256 indexed _id);

  constructor(string memory _tokenName, string memory _tokenSymbol, string memory _baseURI, address _admin) ERC721A(_tokenName, _tokenSymbol) {
    transferOwnership(_admin);
    baseURI = _baseURI;
  }

  function mint(address to) public onlyOwner {
    uint256 tokenId = totalSupply() + 1;
    require(tokenId <= maxSupply, "Can't mint more token");
    _mint(to, 1);
    emit PermanentURI(tokenURI(tokenId), tokenId);
  }

  function baseTokenURI() public view returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override(ERC721A)
    returns (string memory)
  {
    require(_tokenId <= maxSupply, "No existing token with this id");
    return baseTokenURI();
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}