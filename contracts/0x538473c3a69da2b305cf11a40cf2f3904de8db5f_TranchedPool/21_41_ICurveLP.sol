// SPDX-License-Identifier: MIT
// Taken from https://github.com/compound-finance/compound-protocol/blob/master/contracts/CTokenInterfaces.sol
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ICurveLP {
  function token() external view returns (address);

  function get_virtual_price() external view returns (uint256);

  function calc_token_amount(uint256[2] calldata amounts) external view returns (uint256);

  function add_liquidity(
    uint256[2] calldata amounts,
    uint256 min_mint_amount,
    bool use_eth,
    address receiver
  ) external returns (uint256);

  function balances(uint256 arg0) external view returns (uint256);
}