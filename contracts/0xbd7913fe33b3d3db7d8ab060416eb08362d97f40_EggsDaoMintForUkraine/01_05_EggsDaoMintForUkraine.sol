//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@rari-capital/solmate/src/tokens/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./LilOwnable.sol";

import "hardhat/console.sol";

error WithdrawFailed();
error MintNotActive();
error MaxSupply();
error InsufficientFunds();

contract EggsDaoMintForUkraine is ERC1155, LilOwnable {
  mapping(uint256 => uint256) public maxSupply;
  mapping(uint256 => uint256) public mintPrice;
  mapping(uint256 => uint256) public totalSupply;

  string private _uri;
  bool public mintActive;

  event Mint(uint256 indexed index, address indexed account, uint256 amount, uint256 donation);
  event Received(address sender, uint256 value);
  event Withdraw(uint256 amount);
  event MintActive(bool active);
  event SetURI(string uri);
  event SetMintPrice(uint256 id, uint256 price);
  event SetMaxSupply(uint256 id, uint256 maxSupply);

  constructor(string memory uri_) {
    _uri = uri_;

    // large initial supply to allow more minting for charity
    maxSupply[0] = 100000000;
    maxSupply[1] = 100000000;
    maxSupply[2] = 100000000;

    mintPrice[0] = 0.02 ether;
    mintPrice[1] = 0.2 ether;
    mintPrice[2] = 1 ether;
  }

  function mint(uint256 id, uint256 amount) external payable {
    if (!mintActive) revert MintNotActive();
    if (totalSupply[id] + amount > maxSupply[id]) revert MaxSupply();
    if (msg.value < amount * mintPrice[id]) revert InsufficientFunds();

    _mint(msg.sender, id, amount, "");

    totalSupply[id] += amount;

    emit Mint(id, msg.sender, amount, msg.value);
  }

  function uri(uint256 id) public view override returns (string memory) {
    require(exists(id), "URI: nonexistent token");
    return string(abi.encodePacked(_uri, Strings.toString(id)));
  }

  function baseURI() public view returns (string memory) {
    return _uri;
  }

  function exists(uint256 id) public view virtual returns (bool) {
    return totalSupply[id] > 0;
  }

  function setMaxSupply(uint256 id, uint256 _maxSupply) external {
    if (msg.sender != _owner) revert NotOwner();
    maxSupply[id] = _maxSupply;
    emit SetMaxSupply(id, _maxSupply);
  }

  function setMintPrice(uint256 id, uint256 price) external {
    if (msg.sender != _owner) revert NotOwner();
    mintPrice[id] = price;
    emit SetMintPrice(id, price);
  }

  function setURI(string memory uri_) external {
    if (msg.sender != _owner) revert NotOwner();
    console.log(uri_);
    _uri = uri_;
    emit SetURI(uri_);
  }

  function setMintActive(bool _active) external {
    if (msg.sender != _owner) revert NotOwner();
    mintActive = _active;
    emit MintActive(_active);
  }

  function withdraw() external {
    if (msg.sender != _owner) revert NotOwner();
    
    uint256 amount = address(this).balance;
    (bool success, ) = payable(msg.sender).call{value: amount}('');

    if (!success) revert WithdrawFailed();
    emit Withdraw(amount);
  }

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  function supportsInterface(bytes4 interfaceId) public pure override(ERC1155, LilOwnable) returns (bool) {
    return
      interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
      interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
      interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
  }
}