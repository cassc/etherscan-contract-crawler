// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IFiatMintable.sol";

abstract contract FiatMintable is Ownable, IFiatMintable {
  using ECDSA for bytes32;

  mapping(bytes32 => bool) public executed;

  // Hard cap purchase limit
  uint16 private _purchaseLimit = 10;

  constructor() Ownable() {}
  
  function _mintTokensTo(address to, uint amount) internal virtual;
  
  function mint(uint amount, address to, uint expiryDate, bytes calldata signature) external override payable {
    bytes32 transactionHash = getTransactionHash(amount, to, expiryDate, msg.value);

    require(amount <= _purchaseLimit, "EXCEEDED_PURCHASE_LIMIT");
    require(!executed[transactionHash], "TRANSACTION_ALREADY_EXECUTED");
    require(expiryDate > block.timestamp, "TRANSACTION_EXPIRED");
    require(verifySignature(signature, transactionHash), "INVALID_SIGNATURE");

    _mintTokensTo(to, amount);

    executed[transactionHash] = true;
  }
  
  function reservedMint(uint amount, address to) external override onlyOwner {
    _mintTokensTo(to, amount);
  }

  function withdrawFunds() external override onlyOwner {
    uint balance = address(this).balance;
    (bool success,) = payable(msg.sender).call{value: balance}("");
    require(success, "WITHDRAWAL_FAILED");
  }

  function getPurchaseLimit() external override view returns (uint16) {
    return _purchaseLimit;
  }

  function setPurchaseLimit(uint16 amount) external override onlyOwner {
    _purchaseLimit = amount;
  }

  function getTransactionHash(uint amount, address to, uint expiryDate, uint value) public view returns (bytes32) {
    return keccak256(abi.encodePacked(address(this), amount, to, expiryDate, value));
  }

  function verifySignature(bytes memory signature, bytes32 transactionHash) private view returns (bool) {
    address signer = transactionHash.toEthSignedMessageHash().recover(signature);
    return owner() == signer;
  }
}