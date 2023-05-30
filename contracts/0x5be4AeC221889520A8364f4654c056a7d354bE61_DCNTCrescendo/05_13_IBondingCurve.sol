// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBondingCurve {
  event CurvedMint(
    address indexed sender,
    uint256 amount,
    uint256 id,
    uint256 deposit
  );
  event CurvedBurn(
    address indexed sender,
    uint256 amount,
    uint256 id,
    uint256 reimbursement
  );

  function calculateCurvedMintReturn(uint256 amount, uint256 id)
    external
    view
    returns (uint256);

  function calculateCurvedBurnReturn(uint256 amount, uint256 id)
    external
    view
    returns (uint256);
}