// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract RecursivePunks is DefaultOperatorFilterer, ERC721A, ReentrancyGuard, Ownable{
  uint256 public MAX_COLLECTION_SIZE=1500;
  uint256 public maxMintPerWallet=1;
  uint256 public mintPrice = 0.0069 ether;
  constructor() ERC721A("RecursivePunks", "RP") {
    _safeMint(msg.sender, 1);
  }
  function mint() external payable{
    require(totalSupply() < MAX_COLLECTION_SIZE, "Reached max supply");
    require(_numberMinted(msg.sender) < maxMintPerWallet, "Max 1 mint per wallet!");
    require(msg.value >= mintPrice, "Funds not enough");
    _safeMint(msg.sender, 1);
  }
  function tokenURI(uint256 tokenId) public view override returns (string memory){
    return string.concat("https://recursive-punk.vercel.app/",
                        Strings.toString(tokenId)
                        );
  }
  function withdraw() external nonReentrant onlyOwner{
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
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