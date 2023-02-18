// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlurBears is ERC721A, Ownable  {
  uint256 public cost = 0.0042 ether;
  uint256 public maxSupply = 8888;
  uint256 public maxPerWallet = 20;
  uint256 public maxPerTx = 10;
  uint256 public freeMintMax = 1;
  uint256 public freeMintSupply = 8888;

  bool public sale = false;

  constructor(
  ) ERC721A("BlurBears", "BB") payable {
  }

  function mint(uint256 _amount) external payable {
    require(sale, "Sale isn't active");
    require(_totalMinted() + _amount <= maxSupply, "Max Supply");
    require(_numberMinted(msg.sender) + _amount <= maxPerWallet, "20 max!");
    require(_amount <= maxPerTx, "10 per tx!");

    uint256 paidMints = _amount;
    if (_numberMinted(msg.sender) == 0) {
        paidMints -= 1;
    } 

    require(msg.value >= cost * paidMints, "Not enough ETH");
    _safeMint(msg.sender, _amount);
  }

  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }
  
  function setSupply(uint256 _newSupply) external onlyOwner {
    maxSupply = _newSupply;
  }
  
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }
  
  function setMaxPerTx(uint256 _newMax) external onlyOwner {
    maxPerTx = _newMax;
  }

  function setMaxPerWallet(uint256 _newMax) external onlyOwner {
    maxPerWallet = _newMax;
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

  function mintTo(uint256 _amount, address _to) external onlyOwner {
    require(_totalMinted() + _amount <= maxSupply, "Max Supply");
    _mint(_to, _amount);
  }

  //WITHDRAW
  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}