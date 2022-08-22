// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title: Murakami Lucky Cat Coin Bank Sale
/// @author: niftykit.com

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import './interfaces/INiftyKit.sol';
import './MurakamiLuckyCatCoinBank.sol';

contract MurakamiLuckyCatCoinBankSale is AccessControl {
  using Address for address;
  using MerkleProof for bytes32[];

  bool private _active;
  bytes32 private _merkleRoot;
  uint256 private _maxSupply;
  uint256 private _maxPerWallet;
  uint256 private _price;
  uint256 private _totalSupply;
  address private _treasury;

  mapping(address => uint256) private _mintCount;

  MurakamiLuckyCatCoinBank private _catCoinBank;
  INiftyKit private _niftyKit;

  constructor(
    uint256 maxSupply_,
    uint256 maxPerWallet_,
    uint256 price_,
    address catCoinBankAddress_,
    address niftyKit_,
    address treasury_
  ) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    _maxSupply = maxSupply_;
    _maxPerWallet = maxPerWallet_;
    _price = price_;
    _treasury = treasury_;
    _catCoinBank = MurakamiLuckyCatCoinBank(catCoinBankAddress_);
    _niftyKit = INiftyKit(niftyKit_);
  }

  function setMaxSupply(uint256 newMaxSupply)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _maxSupply = newMaxSupply;
  }

  function setMaxPerWallet(uint256 newMaxPerWallet)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _maxPerWallet = newMaxPerWallet;
  }

  function setPrice(uint256 newPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _price = newPrice;
  }

  function setActive(bool newActive) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _active = newActive;
  }

  function setMerkleRoot(bytes32 newRoot)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _merkleRoot = newRoot;
  }

  function setCatCoinBank(address catCoinBankAddress)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _catCoinBank = MurakamiLuckyCatCoinBank(catCoinBankAddress);
  }

  function transferCoinBankOwnership(address newOwner)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _catCoinBank.transferOwnership(newOwner);
  }

  function setBaseURI(string memory newBaseURI)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _catCoinBank.setBaseURI(newBaseURI);
  }

  function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(address(this).balance > 0, '0 balance');

    uint256 balance = address(this).balance;
    uint256 fees = _niftyKit.getFees(address(this));

    _niftyKit.addFeesClaimed(fees);
    Address.sendValue(payable(address(_niftyKit)), fees);
    Address.sendValue(payable(_treasury), balance - fees);
  }

  function airdrop(
    address[] calldata recipients,
    uint256[] calldata numberOfTokens
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(
      numberOfTokens.length == recipients.length,
      'Invalid number of tokens'
    );

    uint256 length = recipients.length;
    for (uint256 i = 0; i < length; ) {
      uint256 quantity = numberOfTokens[i];
      _catCoinBank.mint(recipients[i], quantity);
      unchecked {
        _totalSupply += quantity;
        i++;
      }
    }
  }

  function resetMintCount(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _mintCount[user] = 0;
  }

  function mint(uint256 quantity, bytes32[] calldata proof) external payable {
    uint256 mintQuantity = _mintCount[_msgSender()] + quantity;
    require(_active, 'Not active');
    require(_merkleRoot != '', 'Presale not set');
    require(quantity > 0, 'Quantity is 0');
    require(_price * quantity <= msg.value, 'Value incorrect');
    require(mintQuantity <= _maxPerWallet, 'Exceeded max');
    require(_totalSupply + quantity <= _maxSupply, 'Exceeded max supply');
    require(
      MerkleProof.verify(
        proof,
        _merkleRoot,
        keccak256(abi.encodePacked(_msgSender()))
      ),
      'Not part of list'
    );

    unchecked {
      _mintCount[_msgSender()] = mintQuantity;
      _totalSupply += quantity;
    }

    _niftyKit.addFees(msg.value);
    _catCoinBank.mint(_msgSender(), quantity);
  }

  function treasury() external view returns (address) {
    return _treasury;
  }

  function maxSupply() external view returns (uint256) {
    return _maxSupply;
  }

  function maxPerWallet() external view returns (uint256) {
    return _maxPerWallet;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function price() external view returns (uint256) {
    return _price;
  }

  function active() external view returns (bool) {
    return _active;
  }
}