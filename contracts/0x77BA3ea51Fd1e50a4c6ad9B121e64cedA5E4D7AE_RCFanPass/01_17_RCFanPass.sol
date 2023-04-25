// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract RCFanPass is ERC721A, ERC2981, Pausable, Ownable, DefaultOperatorFilterer {

 using Strings for uint256;

 uint256 public constant MAX_SUPPLY = 20500;
 uint256 public MAX_MINT_PER_WALLET = 2;
 string uriSuffix = ".json";

 bool public publicMintEnabled = false;

 string public baseTokenURI;

 modifier publicMintable() {
 require(publicMintEnabled, "Public minting is not enabled");
 _;
 }

 enum trait {
 VIP_FAN_PASS,
 OG_FAN_PASS,
 META_FAN_PASS
 }

 constructor(string memory _name, string memory _symbol, string memory _baseTokenURI, address _royaltyReceiver, uint96 _defaultRoyaltyValue) ERC721A(_name, _symbol) {
 baseTokenURI = _baseTokenURI;
 _setDefaultRoyalty(_royaltyReceiver, _defaultRoyaltyValue);
 }

 function adminMint(uint256 _count, address _receiver) public onlyOwner whenNotPaused {
 require(_nextTokenId() + _count <= MAX_SUPPLY+1, "Max supply reached");
 _safeMint(_receiver, _count);
 }

 function publicMint(uint256 _count) public whenNotPaused publicMintable {
 require(_count <= MAX_MINT_PER_WALLET, "Exceeds max mint per wallet");
 require(_nextTokenId() >= 5500, "Can't public mint yet");
 require(_nextTokenId() + _count <= MAX_SUPPLY+1, "Max supply reached");
 _safeMint(msg.sender, _count);
 }

 function getTrait(uint256 _tokenId) public pure returns (trait) {
 if (_tokenId <= 500) {
 return trait.VIP_FAN_PASS;
 } else if (_tokenId <= 5500) {
 return trait.OG_FAN_PASS;
 } else {
 return trait.META_FAN_PASS;
 }
 }

 function setMaxMintPerWallet(uint256 _newMaxMintPerWallet) public onlyOwner {
 MAX_MINT_PER_WALLET = _newMaxMintPerWallet;
 }

 function setRoyalty(address _newRoyaltyReceiver, uint96 _newRoyaltyValue) public onlyOwner {
 _setDefaultRoyalty(_newRoyaltyReceiver, _newRoyaltyValue);
 }

 function pause() public onlyOwner whenNotPaused {
 _pause();
 }

 function unpause() public onlyOwner whenPaused {
 _unpause();
 }

 function flipPublicMint() public onlyOwner {
 publicMintEnabled = !publicMintEnabled;
 }

 function setBaseURI(string memory _newBaseURI) public onlyOwner {
 baseTokenURI = _newBaseURI;
 }

 function setURISuffix(string memory _newURISuffix) public onlyOwner {
 uriSuffix = _newURISuffix;
 }

 function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
 require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
 string memory currentBaseUri = _baseURI();
 return bytes(currentBaseUri).length > 0 ? string(abi.encodePacked(currentBaseUri, tokenId.toString(), uriSuffix)) : "";
 }

 function _baseURI() internal view virtual override returns (string memory) {
 return baseTokenURI;
 }

 function setApprovalForAll(address operator, bool approved) public virtual override whenNotPaused onlyAllowedOperatorApproval(operator) {
 super.setApprovalForAll(operator, approved);
 }

 function approve (address to, uint256 tokenId) public payable virtual override whenNotPaused onlyAllowedOperatorApproval(to) {
 super.approve(to, tokenId);
 }

 function transferFrom(address from, address to, uint256 tokenId) public payable virtual override whenNotPaused onlyAllowedOperator(from) {
 super.transferFrom(from, to, tokenId);
 }

 function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual override whenNotPaused onlyAllowedOperator(from) {
 super.safeTransferFrom(from, to, tokenId);
 }

 function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable virtual override whenNotPaused onlyAllowedOperator(from) {
 super.safeTransferFrom(from, to, tokenId, data);
 }

 function withdraw(address tokenAddress) public onlyOwner {
 if (tokenAddress == address(0)) {
 payable(msg.sender).transfer(address(this).balance);
 } else {
 IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
 }
 }

 function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
 return super.supportsInterface(interfaceId);
 }

 function _startTokenId() internal pure virtual override returns (uint256) {
 return 1;
 }

}