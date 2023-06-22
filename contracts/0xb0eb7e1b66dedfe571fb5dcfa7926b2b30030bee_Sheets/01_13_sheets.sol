// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract Sheets is DefaultOperatorFilterer, ERC721A, ReentrancyGuard, Ownable{
  uint256 public MAX_COLLECTION_SIZE=520;
  uint256 public maxMintPerWallet=2;
  uint256 public maxMintPerTx=1;
  constructor() ERC721A("Sheets", "sheet") {
    _safeMint(msg.sender, 1);
  }
  function mint() external {
    require(totalSupply() < MAX_COLLECTION_SIZE, "Reached max supply");
    require(_numberMinted(msg.sender) < maxMintPerWallet, "Max 2 mint per wallet!");
    _safeMint(msg.sender, 1);
  }
  function tokenURI(uint256 tokenId) public view override returns (string memory){
    return string.concat("ipfs://QmRzzDhiTgx5VfxdXbv5y7u67g9CM9T96mCCcDr9A5t4Jv/",
                        Strings.toString(tokenId));
  }
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }
  function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }
  function transferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from){
    super.transferFrom(from, to, tokenId);
  }
  function safeTransferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override payable onlyAllowedOperator(from){
    super.safeTransferFrom(from, to, tokenId, data);
  }
}