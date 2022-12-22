// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/*
  @@@ .............     .................     .........    ..............   [email protected]@ 
  @@@ ...............   .................  ..............  ................ [email protected]@ 
  @@@ ......     ...... ......           .......     ............      [email protected]@ 
  @@@ ......     ...... .............    .......     ............      [email protected]@ 
  @@@ ......     ...... .............    ........................      [email protected]@ 
  @@@ ......     ...... ......           ........................      [email protected]@ 
  @@@ ...............   ........................     .....................   @@ 
  @@@                                                                      @@@@ 
  . @@@@@@@@@@@  [email protected]@@@@@@@@@ [email protected]@@@ @@@@@@@@@@@@@@@@@@@@   @@@ @@@@@@,  @@@@@@@@ 
  [email protected]@@     [email protected]@@##%@@@@@@  &@@@@@@@/@@%###    [email protected]@@  [email protected]@@/@@@@@@@@  #@@@@@@####   
  [email protected]@@     [email protected]@@  [email protected]@@@@@@@@@@[email protected]@@@     [email protected]@@  [email protected]@@  [email protected]@@  [email protected]@@@@@@@@@@@   [email protected]@@@ 
  . [email protected]@@@@@@@@@  [email protected]@@@@@  [email protected]@@@@@@@@@@@@@    [email protected]@@  [email protected]@@  [email protected]@@@@@ .#@@@@@@@@@@.

*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeadChristmas is ERC721A, Ownable  {
  uint256 public cost = 0.0045 ether;
  uint256 public maxSupply = 5454;
  string public baseURI;
  bool public sale = false;

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721A(_name, _symbol) payable {
  }

  function mint(uint256 _amount) external payable {
    require(sale, "Sale isn't active");
    require(_totalMinted() + _amount < maxSupply + 1, "Max Supply");
    require(_amount < 4, "3 per");
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