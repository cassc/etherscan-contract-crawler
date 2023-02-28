// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './ERC1155PresetMinter.sol';

contract Diamond is ERC1155PresetMinter, ReentrancyGuard {
  using Strings for uint256;

  string private _name;
  string private _symbol;
  string public baseTokenURI;
  string public uriSuffix = '.json';

  address operationsAddress;
  address payee;

  uint256 public constant FEE_DENOMINATOR = 10000;
  uint256 public operationsFee;

  struct SalePrice {
    string category;
    uint256 price;
    bool exists;
  }

  uint numCategories;
  mapping (uint => SalePrice) salePrices;

  constructor(
    string memory uri_,
    string memory name_,
    string memory symbol_
  ) ERC1155PresetMinter('') {
    _name = name_;
    _symbol = symbol_;
    baseTokenURI = uri_;
    operationsFee = 1000;
    payee = _msgSender();
    operationsAddress = _msgSender();
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function safeTransfer(address to, uint256 id, uint256 amount) public virtual {
    return safeTransferFrom(_msgSender(), to, id, amount, '');
  }

  function auctionMint(uint256 id, uint256 amount, uint saleID) external payable callerIsUser {
    require(amount >= 0, "amount must be greater than 0");
    uint256 totalCost = getAuctionPrice(saleID) * amount;
    _mint(msg.sender, id, amount, '');

    payIfOver(totalCost);
  }

  function getAuctionPrice(uint saleID)
    public
    view
    returns (uint256)
  {
    require(salePrices[saleID].exists, "Sale does not exist.");
    SalePrice storage s = salePrices[saleID];
    return uint256(s.price);
  }

  function payIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more BNB.");

    uint256 bnbForPayee = msg.value;
    uint256 fee = (msg.value * operationsFee) / FEE_DENOMINATOR;

    if (fee > 0) {
      bnbForPayee -= fee;
      (bool hs, ) = address(operationsAddress).call{value: fee}('');
      require(hs, "Fee transfer failed.");
    }

    (bool os, ) = address(payee).call{ value: bnbForPayee }('');
    require(os, "Transfer failed.");

  }

  function uri(uint256 _tokenID) public view override returns (string memory) {
    require(exists(_tokenID), 'URI query for nonexistent token');
    string memory currentBaseURI = _baseURI();
    return
      string(abi.encodePacked(currentBaseURI, _tokenID.toString(), uriSuffix));
  }

  function setBaseURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function _baseURI() internal view returns (string memory) {
    return baseTokenURI;
  }

  function setOperationsAddress(address operationsNewAddress)
    external
    onlyOwner
  {
    require(operationsNewAddress != address(0));
    operationsAddress = payable(operationsNewAddress);
  }

  function setPayeeAddress(address payeeNewAddress)
    external
    onlyOwner
  {
    require(payeeNewAddress != address(0));
    payee = payable(payeeNewAddress);
  }

  function updateFees(uint256 fee)
    external
    onlyOwner
  {
    operationsFee = fee;
  }

  function setNewSalePrice(
    string memory category,
    uint256 price
  ) public onlyOwner returns(uint saleID){

    saleID = numCategories ++;
    SalePrice storage s = salePrices[saleID];
    s.category = category;
    s.price = price;
    s.exists = true;

  }

  function setSalePrice(
    string memory category,
    uint256 price,
    bool exist,
    uint saleID
  ) external onlyOwner{

    SalePrice storage s = salePrices[saleID];
    s.category = category;
    s.price = price;
    s.exists = exist;

  }

}