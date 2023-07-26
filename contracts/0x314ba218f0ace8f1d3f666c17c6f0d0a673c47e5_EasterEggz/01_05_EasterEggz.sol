// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EasterEggz is ERC721A, Ownable  {
  uint256 public maxSupply = 5000;
  uint256 public maxFreeSupply = 5000;
  uint256 public maxFreePerWallet = 1;
  uint256 public cost = 0.0025 ether;
  uint256 public maxPerWallet = 5;

  bool public sale = false;
  string public baseURI;

  error SaleNotActive();
  error MaxSupplyReached();
  error MaxPerWalletReached();
  error NotEnoughETH();
  error NoContractMint();

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721A(_name, _symbol) {
    baseURI = "ipfs://bafybeic3buo6pdiwmypjs2hzljrn7jwejxl66w2q6kbkktknthqa4obul4/";
  }

  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }
  
  function setSupply(uint256 _newSupply) external onlyOwner {
    maxSupply = _newSupply;
  }

  function setMaxPerWallet(uint256 _newMax) external onlyOwner {
    maxPerWallet = _newMax;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function setBaseURI(string calldata _newURI) external onlyOwner {
    baseURI = _newURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function startEggHunt(bool _toggle) external onlyOwner {
    sale = _toggle;
  }

  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function mintEgg(uint256 _amount) external payable {
    if (tx.origin != msg.sender) revert NoContractMint();
    if (!sale) revert SaleNotActive();
    if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
    if (_numberMinted(msg.sender) + _amount > maxPerWallet) revert MaxPerWalletReached();

    uint256 paid = _amount;
    if (_numberMinted(msg.sender) == 0) {
        paid -= 1;
    }
    if (msg.value < cost * paid) revert NotEnoughETH();
    _mint(msg.sender, _amount);
  }
  
  function ownerMint(uint256 _amount, address _to) external onlyOwner {
    if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
    _mint(_to, _amount);
  }
}