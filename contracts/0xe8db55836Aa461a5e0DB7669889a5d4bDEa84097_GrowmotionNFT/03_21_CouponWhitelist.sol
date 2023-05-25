// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./AbstractWhitelist.sol";

abstract contract CouponWhitelist is AbstractWhitelist {
  using SafeMath for uint256;

  address public couponSigner;
  mapping(address => uint256) public minted;

  constructor(address couponSigner_) {
    couponSigner = couponSigner_;
  }

  function setCouponSigner(address couponSigner_) external onlyOwner {
    couponSigner = couponSigner_;
  }

  modifier isWhitelisted(
    uint256 mintAmount_,
    uint256 maxMintAmount_,
    bytes memory signature_
  ) {
    require(isWhitelistSale, "not whitelist sale");
    require(minted[msg.sender].add(mintAmount_) <= maxMintAmount_, "maxAmount minted");

    bytes32 hash = ECDSA.toEthSignedMessageHash(
      keccak256(abi.encodePacked(msg.sender, maxMintAmount_))
    );
    address signer = ECDSA.recover(hash, signature_);
    require(signer == couponSigner, "not coupon signer");

    minted[msg.sender] += mintAmount_;
    _;
  }
}