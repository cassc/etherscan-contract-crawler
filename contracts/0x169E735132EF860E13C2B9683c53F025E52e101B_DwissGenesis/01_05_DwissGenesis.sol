// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "solmate/src/auth/Owned.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DwissGenesis is Owned, ERC721A {
  bytes32 public whitelistRootHash;
  string baseURI;

  // packed
  uint64 public price;
  uint32 public presaleStart;
  uint32 public saleStart;
  bool public isSaleClosed;

  address payable public treasury;

  uint public immutable maxSupply = 5000;

  constructor (
    string memory _name,
    string memory _symbol
  ) Owned(msg.sender) ERC721A(_name, _symbol) {
    // noop
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function mint(
    uint amount,
    bytes32[] memory proof
  ) public payable {

    // SLOAD
    uint _price = price;
    uint _presaleStart = presaleStart;
    uint _saleStart = saleStart;
    bool _isSaleClosed = isSaleClosed;

    address _treasury = treasury;
    uint _totalSupply = totalSupply();

    require(!_isSaleClosed, "Sale has closed");
    require(_price != 0, "Price not set");
    require(_treasury != address(0), 'No treasury address set');

    if (_totalSupply + amount > maxSupply) {
      amount = maxSupply - _totalSupply;
      require(amount > 0, "Max supply reached");
    }

    if (proof.length != 0) {
      require(block.timestamp >= _presaleStart, "Presale has not started yet");
      bytes32 leaf = bytes32(uint(uint160(msg.sender)));
      require(MerkleProof.verify(proof, whitelistRootHash, leaf), "Invalid whitelist proof");
      _price = _price * 9 / 10;
    } else {
      require(block.timestamp >= _saleStart, "Sale has not started yet");
    }

    _mint(msg.sender, amount);

    uint cost = amount * _price;
    require(msg.value >= cost, "Not enough ETH sent");

    if (msg.value > cost) {
      uint refund = msg.value - cost;
      (bool refundOK, /* data */) = msg.sender.call{value : refund}("");
      require(refundOK, "Refund failed");
    }

    (bool transferOK, /* data */) = _treasury.call{value : cost}("");
    require(transferOK, "Transfer failed");
  }

  function getSaleStatus() public view returns (
    uint _price,
    uint _totalSupply,
    uint _presaleStart,
    uint _saleStart,
    uint _timeTillPresaleStart,
    uint _timeTillSaleStart,
    bool _isSaleClosed
  ) {
    _price = price;
    _totalSupply = totalSupply();
    _presaleStart = presaleStart;
    _saleStart = saleStart;
    _isSaleClosed = isSaleClosed;
    _timeTillPresaleStart = _presaleStart > block.timestamp ? _presaleStart - block.timestamp : 0;
    _timeTillSaleStart = _saleStart > block.timestamp ? _saleStart - block.timestamp : 0;
  }

  function setPrice(uint64 _price) public onlyOwner {
    price = _price;
  }

  function setPresaleStart(uint32 _presaleStart) public onlyOwner {
    require(_presaleStart >= block.timestamp, 'presale start < now');
    presaleStart = _presaleStart;
  }

  function setSaleStart(uint32 _saleStart) public onlyOwner {
    require(_saleStart >= block.timestamp, 'sale start < now');
    saleStart = _saleStart;
  }

  function setSaleStatus(bool _isSaleClosed) public onlyOwner {
    isSaleClosed = _isSaleClosed;
  }

  function finalizeSale(address destination) public onlyOwner {
    isSaleClosed = true;
    uint amountLeft = maxSupply - totalSupply();
    while (amountLeft > 0) {
      uint batchSize = amountLeft > 100 ? 100 : amountLeft;
      amountLeft -= batchSize;
      _mint(destination, batchSize);
    }
  }

  function _baseURI() internal view override returns (string memory) {
      return baseURI;
  }

  function setURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function setWhitelistRootHash(bytes32 _whitelistRootHash) public onlyOwner {
    whitelistRootHash = _whitelistRootHash;
  }

  function setTreasury(address payable _treasury) public onlyOwner {
    treasury = _treasury;
  }

  function withdraw() public onlyOwner {
    require(treasury != address(0), 'No treasury address set');
    uint balance = address(this).balance;
    (bool ok, /* data */) = treasury.call{value : balance}("");
    require(ok, "Withdraw failed");
  }

}