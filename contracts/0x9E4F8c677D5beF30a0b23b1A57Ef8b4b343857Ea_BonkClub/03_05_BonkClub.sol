// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract BonkClub is ERC721A, Ownable  {
  uint256 public cost = 0.002 ether;
  uint256 public maxSupply = 10000;
  string public baseURI;
  uint256 public mintMax = 10;
  uint256 public mintPerTx = 5;
  bool public sale = false;


  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721A(_name, _symbol) payable {
  }

  function mint(uint256 _amount) external payable {
    require(sale, "Sale isn't active");
    require(_totalMinted() + _amount < maxSupply + 1, "Max Supply");
    require(_numberMinted(msg.sender) + _amount < mintMax + 1, "10 per wallet");
    require(_amount < mintPerTx + 1);
    require(msg.value == cost * _amount, "NOT ENOUGH ETHER");
    _safeMint(msg.sender, _amount);
  }

  function ownerMint(uint256 _amount) external onlyOwner {
    require(_totalMinted() + _amount < maxSupply + 1, "Max Supply");
    _mint(msg.sender, _amount);
  }

  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }

  //METADATA
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function setBaseURI(string calldata _newURI) external onlyOwner {
    baseURI = _newURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function toggleSale(bool _toggle) external onlyOwner {
    sale = _toggle;
  }

  //WITHDRAW
  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}