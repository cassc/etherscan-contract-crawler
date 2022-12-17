// SPDX-License-Identifier: PROTECTED
// [email protected]
pragma solidity ^0.8.0;

interface ITokenized {
  function feedPrice(address feed) external view returns (uint256);

  function tokenPrice(address token) external view returns (uint256);

  function allPriceFeeds() external view returns (address[] memory);

  function allTokens() external view returns (address[] memory);

  function allTokensDetails()
    external
    view
    returns (
      address[] memory addresses,
      string[] memory symbols,
      uint256[] memory decimals,
      uint256[] memory prices
    );

  function userTokenBalance(address user, address token) external view returns (uint256);

  function userTokenAllowance(
    address user,
    address token
  ) external view returns (uint256);

  function userTokensDetails(
    address user
  )
    external
    view
    returns (
      string[] memory symbols,
      uint256[] memory balances,
      uint256[] memory allowances
    );
}