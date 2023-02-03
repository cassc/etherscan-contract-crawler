// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Hellings is ERC721A, Ownable  {
  uint256 public COST = 0.004 ether;
  uint256 public MAX_SUPPLY = 6666;
  uint256 public MAX_PER_WALLET = 6;
  uint256 public MAX_PER_TX = 3;
  bool public sale = false;

  constructor(
  ) ERC721A("HELLINGS", "HELL") payable {
  }

  function mintHelling(uint256 _amount) external payable {
    require(sale, "Can't Go To Hell Yet!");
    require(_totalMinted() + _amount < MAX_SUPPLY + 1, "All Hellings have spawned");
    require(_numberMinted(msg.sender) + _amount < MAX_PER_WALLET + 1, "Can't spawn anymore hellings!");
    require(_amount < MAX_PER_TX + 1, "3 per tx!");
    require(msg.value == COST * _amount, "NOT ENOUGH ETHER");
    _safeMint(msg.sender, _amount);
  }

  function setCost(uint256 _cost) external onlyOwner {
    COST = _cost;
  }
  
  function setSupply(uint256 _newSupply) external onlyOwner {
    MAX_SUPPLY = _newSupply;
  }
  
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  //METADATA
  string public baseURI;

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

  function spawnTo(uint256 _amount, address _to) external onlyOwner {
    require(_totalMinted() + _amount < MAX_SUPPLY + 1, "Max Supply");
    _mint(_to, _amount);
  }

  //WITHDRAW
  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}