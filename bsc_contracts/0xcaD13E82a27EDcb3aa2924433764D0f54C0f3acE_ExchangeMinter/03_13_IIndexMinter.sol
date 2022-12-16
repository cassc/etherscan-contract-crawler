// SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

import "../interfaces/IIndexToken.sol";

interface IIndexMinter {
  struct RedeemResult {
    address token;
    uint256 amount;
  }

  function issue(IIndexToken token, uint256 amount) external;
  function redeem(IIndexToken token, uint256 amount) external returns (RedeemResult[] memory);
}