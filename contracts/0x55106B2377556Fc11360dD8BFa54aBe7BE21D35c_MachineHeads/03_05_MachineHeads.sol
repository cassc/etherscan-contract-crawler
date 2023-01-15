// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MachineHeads is ERC721A, Ownable  {
  uint256 public cost = 0.0039 ether;
  uint256 public maxSupply = 7000;
  uint256 public maxPerWallet = 20;
  uint256 public maxPerTx = 10;
  string public baseURI;
  bool public sale = false;

  constructor(
  ) ERC721A("MachineHeads", "MCHD") payable {
  }

  function mint(uint256 _amount) external payable {
    require(sale, "Sale isn't active");
    require(_totalMinted() + _amount < maxSupply + 1, "Max Supply");
    require(_numberMinted(msg.sender) + _amount < maxPerWallet + 1, "20 max!");
    require(_amount < maxPerTx + 1, "10 per tx!");

    uint256 paidMints = _amount;
    if (_numberMinted(msg.sender) == 0) {
        paidMints -= 1;
    } 

    require(msg.value >= cost * paidMints, "Not enough ETH");
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

  function setSupply(uint256 _newSupply) external onlyOwner {
    maxSupply = _newSupply;
  }

  //WITHDRAW
  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}