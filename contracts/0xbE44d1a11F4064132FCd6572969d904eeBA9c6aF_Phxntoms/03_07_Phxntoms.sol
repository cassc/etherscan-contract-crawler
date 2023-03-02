// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract Phxntoms is ERC721ABurnable, Ownable  {
  uint256 public cost = 0.004 ether;
  uint256 public maxSupply = 3333;
  uint256 public maxPerWallet = 5;
  uint256 public maxPerTx = 5;
  bool public sale = false;

  error SaleNotActive();
  error MaxSupplyReached();
  error MaxPerWalletReached();
  error MaxPerTxReached();
  error NotEnoughETH();
  error NoContractMint();

  constructor(
  ) ERC721A("Phxntoms", "BOO") payable {
    baseURI = "ipfs://bafybeigzxaroddem3eazztjljknaryelryfvbiw2owwr2bcxcbtiqvy734/";
  }

  function mint(uint256 _amount) external payable {
    if (tx.origin != msg.sender) revert NoContractMint();
    if (!sale) revert SaleNotActive();
    if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
    if (_numberMinted(msg.sender) + _amount > maxPerWallet) revert MaxPerWalletReached();
    if (_amount > maxPerTx) revert MaxPerTxReached();
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
    if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
    _mint(_to, _amount);
  }

  //WITHDRAW
  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}