// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract To_GPT_From_GPT is ERC721A, Ownable  {
  uint256 public maxSupply = 555;
  uint256 public maxPerWallet = 25;
  uint256 public maxPerTx = 25;
  uint256 public cost = 0.002 ether;
  bool public sale = false;

  error SaleNotActive();
  error MaxSupplyReached();
  error MaxPerWalletReached();
  error MaxPerTxReached();
  error NotEnoughETH();

  constructor(string memory __name, string memory __symbol) ERC721A(__name, __symbol){}

  function mintGPT(uint256 _amount) external payable {
    if (!sale) revert SaleNotActive();
    if (_totalMinted() + _amount >= maxSupply) revert MaxSupplyReached();
    if (_numberMinted(msg.sender) + _amount >= maxPerWallet) revert MaxPerWalletReached();
    if (_amount >= maxPerTx) revert MaxPerTxReached();
    if (msg.value < cost * _amount) revert NotEnoughETH();

    _mint(msg.sender, _amount);
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

  function setMaxPerWallet(uint256 _newMaxPerWallet) external onlyOwner {
    maxPerWallet = _newMaxPerWallet;
  }

  function setMaxPerTx(uint256 _newMaxPerTx) external onlyOwner {
    maxPerTx = _newMaxPerTx;
  }
}