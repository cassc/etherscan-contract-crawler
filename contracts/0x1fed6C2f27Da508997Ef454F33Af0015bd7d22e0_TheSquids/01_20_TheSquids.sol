// SPDX-License-Identifier: MIT
// Creator: https://cojodi.com
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "cojodi/contracts/access/MerkleWhitelist.sol";
import "cojodi/contracts/sell/BasicSellOne.sol";

import "./TheSquidsBase.sol";

contract TheSquids is TheSquidsBase, MerkleWhitelist, BasicSellOne {
  using SafeMath for uint256;

  address private dev1;
  address private projectOwner;

  constructor(
    address dev1_,
    address projectOwner_
  )
    TheSquidsBase()
    MerkleWhitelist(0x90545df517c529667432ef0384156da9e2430e7e17bf6f5119393d5e953fd54d)
    BasicSellOne(0.1 ether)
  {
    dev1 = dev1_;
    projectOwner = projectOwner_;
  }

  function mintWhitelist(bytes32[] calldata merkleProof_)
    external
    payable
    isWhitelisted(merkleProof_)
    isPaymentOk
  {
    _safeMint(msg.sender);
  }

  function mintPublic() external payable isPublic isPaymentOk {
    _safeMint(msg.sender);
  }

  function mintOwner(address receiver_, uint256 amount_) external onlyOwner {
    for (uint256 i = 0; i < amount_; ++i) _safeMint(receiver_);
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(dev1).transfer((balance * 6) / 100);
    payable(projectOwner).transfer((balance * 94) / 100);
  }
}