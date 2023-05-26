// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DarkThoughts is ERC721A, Ownable  {
  uint256 public COST = 0.004 ether;
  uint256 public MAX_SUPPLY = 1984;
  uint256 public MAX_PER_WALLET = 3;
  bool public SALE = false;
  string public baseURI;

  error SaleNotActive();
  error MaxSupplyReached();
  error MaxPerWalletReached();
  error MaxPerTxReached();
  error NotEnoughETH();
  error NoContractMint();

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721A(_name, _symbol) payable {
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

    function darknessSpawn(uint256 _amount) external payable {
    if (tx.origin != msg.sender) revert NoContractMint();
    if (!SALE) revert SaleNotActive();
    if (_totalMinted() + _amount > MAX_SUPPLY) revert MaxSupplyReached();
    if (_numberMinted(msg.sender) + _amount > MAX_PER_WALLET) revert MaxPerWalletReached();
    if (msg.value < COST * _amount) revert NotEnoughETH();

    _mint(msg.sender, _amount);
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

  function toggleSale(bool _toggle) external onlyOwner {
    SALE = _toggle;
  }
  
  function setMaxPerWallet(uint256 _newMaxPerWallet) external onlyOwner {
    MAX_PER_WALLET = _newMaxPerWallet;
  }

  function mintTo(uint256 _amount, address _to) external onlyOwner {
    if (_totalMinted() + _amount > MAX_SUPPLY) revert MaxSupplyReached();
    _mint(_to, _amount);
  }

  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}