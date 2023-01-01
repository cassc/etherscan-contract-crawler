// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ClassOf2022 is ERC721A, Ownable{
  uint256 public price = 0.0022 ether;
  uint256 public max_supply = 2022;
  string public baseURI;
  bool public sale = false;

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721A(_name, _symbol) payable {
  }

  function mint(uint256 _amount) external payable {
    require(sale, "Sale isn't active");
    require(_totalMinted() + _amount < max_supply + 1, "Max Supply Reached");
    require(_amount < 4, "3 per");
    require(msg.value == price * _amount, "NOT ENOUGH ETHER");
    _safeMint(msg.sender, _amount);
  }

  function mintToAddress(uint256 _amount, address _to) external onlyOwner {
    require(_totalMinted() + _amount < max_supply + 1, "Max Supply");
    _mint(_to, _amount);
  }

  function setprice(uint256 _price) external onlyOwner {
    price = _price;
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