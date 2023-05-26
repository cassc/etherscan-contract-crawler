// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./extensions/ERC721AOpensea.sol";
import "./NFTToken.sol";

contract PixelPolARoids is NFTToken, ERC721AOpensea { 
 string private _baseTokenURI;

 uint public MAX_SUPPLY = 282; 
 uint public COST = 0.165 ether;

 bool public mintEnabled = false;

 error ExceedsMaxPerTX();
 error ExceedsMaxSupply();
 error NoMismatchedOrigin();
 error MintNotActive();
 error WithdrawalFailed();
 error WrongETHValueSent();

 modifier enoughSupply(uint256 qty) {
 if (_totalMinted() + qty > MAX_SUPPLY) {
 revert ExceedsMaxSupply();
 }
 _;
 }

 constructor()
 ERC721A("PolARoidPortfolio", "PP")
 ERC721AOpensea()
 NFTToken()
 {}
 
 function mint(uint qty)
 external
 payable 
 enoughSupply(qty)
 { 
 if (!mintEnabled) revert MintNotActive();

 uint price = (COST * qty);
 
 _mint(msg.sender, qty);
 _refundIfOverPayment(price);
 }

 function _refundIfOverPayment(uint256 price) internal {
 if (msg.value < price) revert WrongETHValueSent();
 if (msg.value > price) {
 payable(msg.sender).transfer(msg.value - price); 
 }
 }

 function setMaxTokenSupply(uint256 maxSupply) public onlyOwner {
 MAX_SUPPLY = maxSupply;
 }

 function toggleMintEnabled() external onlyOwner {
 mintEnabled = !mintEnabled;
 }

 function numberMinted(address owner) public view returns (uint256) {
 return _numberMinted(owner);
 }

 function numberBurned(address owner) public view returns (uint256) {
 return _numberBurned(owner);
 }

 function totalBurned() public view returns (uint256) {
 return _totalBurned();
 }

 function setBaseURI(string calldata baseURI_) external onlyOwner {
 _baseTokenURI = baseURI_;
 }

 function supportsInterface(bytes4 interfaceId)
 public
 view
 virtual
 override(NFTToken, ERC721AOpensea)
 returns (bool)
 {
 return
 ERC721A.supportsInterface(interfaceId) ||
 ERC2981.supportsInterface(interfaceId) ||
 AccessControl.supportsInterface(interfaceId);
 }

 function _baseURI() internal view virtual override returns (string memory) {
 return _baseTokenURI;
 }

 function _startTokenId() internal view virtual override returns (uint256) {
 return 1;
 }

 function withdraw() external onlyOwner {
 (bool success, ) = msg.sender.call{value: address(this).balance}("");
 if (!success) revert WithdrawalFailed();
 }

 function whittersMint(uint256 quantity, address to) 
 external 
 onlyOwner
 enoughSupply(quantity)
 {
 _mint(to, quantity);
 }
}