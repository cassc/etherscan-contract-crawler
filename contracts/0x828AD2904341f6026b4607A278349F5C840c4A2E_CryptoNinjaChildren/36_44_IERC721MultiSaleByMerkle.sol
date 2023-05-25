// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "../../Sale.sol";

interface IERC721MultiSaleByMerkle {

  function claim(uint248 amount, uint248 allowedAmount, bytes32[] calldata merkleProof) external payable;
  
  function exchange(uint256[] calldata burnTokenIds, uint248 allowedAmount, bytes32[] calldata merkleProof) external payable;

  function setCurrentSale(Sale calldata sale, bytes32 merkleRoot) external;
}