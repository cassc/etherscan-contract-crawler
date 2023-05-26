// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IDToken is IERC20Metadata {
  /**
   * @dev Emitted when new stable debt is minted
   * @param account The address of the account who triggered the minting
   * @param receiver The recipient of stable debt tokens
   * @param amount The amount minted
   * @param currentBalance The current balance of the account
   * @param balanceIncrease The increase in balance since the last action of the account
   * @param newRate The rate of the debt after the minting
   * @param avgStableRate The new average stable rate after the minting
   * @param newTotalSupply The new total supply of the stable debt token after the action
   **/
  event Mint(
    address indexed account,
    address indexed receiver,
    uint256 amount,
    uint256 currentBalance,
    uint256 balanceIncrease,
    uint256 newRate,
    uint256 avgStableRate,
    uint256 newTotalSupply
  );

  /**
   * @dev Emitted when new stable debt is burned
   * @param account The address of the account
   * @param amount The amount being burned
   * @param currentBalance The current balance of the account
   * @param balanceIncrease The the increase in balance since the last action of the account
   * @param avgStableRate The new average stable rate after the burning
   * @param newTotalSupply The new total supply of the stable debt token after the action
   **/
  event Burn(
    address indexed account,
    uint256 amount,
    uint256 currentBalance,
    uint256 balanceIncrease,
    uint256 avgStableRate,
    uint256 newTotalSupply
  );

  /**
   * @dev Mints debt token to the `receiver` address.
   * - The resulting rate is the weighted average between the rate of the new debt
   * and the rate of the previous debt
   * @param account The address receiving the borrowed underlying, being the delegatee in case
   * of credit delegate, or same as `receiver` otherwise
   * @param receiver The address receiving the debt tokens
   * @param amount The amount of debt tokens to mint
   * @param rate The rate of the debt being minted
   **/
  function mint(
    address account,
    address receiver,
    uint256 amount,
    uint256 rate
  ) external;

  /**
   * @dev Burns debt of `account`
   * - The resulting rate is the weighted average between the rate of the new debt
   * and the rate of the previous debt
   * @param account The address of the account getting his debt burned
   * @param amount The amount of debt tokens getting burned
   **/
  function burn(address account, uint256 amount) external;

  /**
   * @dev Returns the average rate of all the stable rate loans.
   * @return The average stable rate
   **/
  function getTotalAverageRealAssetBorrowRate() external view returns (uint256);

  /**
   * @dev Returns the stable rate of the account debt
   * @return The stable rate of the account
   **/
  function getUserAverageRealAssetBorrowRate(address account) external view returns (uint256);

  /**
   * @dev Returns the timestamp of the last update of the account
   * @return The timestamp
   **/
  function getUserLastUpdateTimestamp(address account) external view returns (uint256);

  /**
   * @dev Returns the principal, the total supply and the average stable rate
   **/
  function getDTokenData()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  /**
   * @dev Returns the timestamp of the last update of the total supply
   * @return The timestamp
   **/
  function getTotalSupplyLastUpdated() external view returns (uint256);

  /**
   * @dev Returns the total supply and the average stable rate
   **/
  function getTotalSupplyAndAvgRate() external view returns (uint256, uint256);

  /**
   * @dev Returns the principal debt balance of the account
   * @return The debt balance of the account since the last burn/mint action
   **/
  function principalBalanceOf(address account) external view returns (uint256);
}