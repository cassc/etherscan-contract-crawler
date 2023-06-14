// SPDX-License-Identifier: GPL-3.0
// Author: Pagzi Tech Inc. | 2022
// Ancient Warriors | 2022
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AncientWarriors is ERC721, Ownable {
  string public baseURI;
  uint256 public supply = 4444;
  uint256 public totalSupply;
  address warriorbuilder = 0xF4617b57ad853f4Bc2Ce3f06C0D74958c240633c;
  address warriorleader = 0xF5682552f035cbcC0C4725e446a8C2FF8b8Ac30A;
  //presale settings
  uint256 public publicDate = 1642449600;

  constructor(
  string memory _initBaseURI
  ) ERC721("Ancient Warriors", "WARRIOR"){
  setBaseURI(_initBaseURI);
  mintVault();
  }
  
  function getPrice(uint256 quantity) public view returns (uint256){
  uint256 totalPrice = 0;
  if (publicDate <= block.timestamp) {
  for (uint256 i = 0; i < quantity; i++) {
  totalPrice += 0.05 ether;
  }
  return totalPrice;
  }
  uint256 current = totalSupply;
  for (uint256 i = 0; i < quantity; i++) {
  if (current >= 600) {
  totalPrice += 0.05 ether;
  } else {
  totalPrice += 0.03 ether;
  }
  current++;
  }
  return totalPrice;
  }
  // public
  function mint(uint256 _mintAmount) public payable{
  require(publicDate <= block.timestamp, "Not yet");
  require(totalSupply + _mintAmount + 1 <= supply, "0" );
  uint256 totalPrice = getPrice(_mintAmount);
  require(msg.value >= totalPrice);
  for (uint256 i; i < _mintAmount; i++) {
  _safeMint(msg.sender, totalSupply + 1 + i);
  }
  totalSupply += _mintAmount;
  }
  function presaleMint(uint256 _mintAmount) public payable{
  require(totalSupply + _mintAmount + 1 <= supply, "0" );
  uint256 totalPrice = getPrice(_mintAmount);
  require(msg.value >= totalPrice);
  for (uint256 i; i < _mintAmount; i++) {
  _safeMint(msg.sender, totalSupply + 1 + i);
  }
  totalSupply += _mintAmount;
  }

  //only owner
  function gift(uint[] calldata quantity, address[] calldata recipient) public onlyOwner{
  require(quantity.length == recipient.length, "Provide quantities and recipients" );
  uint totalQuantity = 0;
  for(uint i = 0; i < quantity.length; ++i){
  totalQuantity += quantity[i];
  }
  require(totalSupply + totalQuantity + 1 <= supply, "0" );
  for(uint i = 0; i < recipient.length; ++i){
  for(uint j = 0; j < quantity[i]; ++j){
  _safeMint(recipient[i], totalSupply + 1);
	totalSupply++;
  }
  }
  }
  function withdraw() public onlyOwner {
  uint256 balance = address(this).balance;
  payable(warriorbuilder).transfer((balance * 150) / 1000);
  payable(warriorleader).transfer((balance * 850) / 1000);
  }  
  function setSupply(uint256 _supply) public onlyOwner {
  supply = _supply;
  }
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
  baseURI = _newBaseURI;
  }
  
  //internal
  function mintVault() internal {
  for (uint256 i; i < 100; i++) {
  _safeMint(warriorleader, totalSupply + 1 + i);
  }
  totalSupply = 100;
  }
  function _baseURI() internal view override returns (string memory) {
  return baseURI;
  }
}