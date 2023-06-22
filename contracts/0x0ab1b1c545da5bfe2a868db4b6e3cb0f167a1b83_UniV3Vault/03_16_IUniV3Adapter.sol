// SPDX-License-Identifier: MIT

import "./IAdapter.sol";

pragma solidity 0.8.18;

/// @title Saffron Fixed Income Uniswap V3 Adapter
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Manages a pair of assets deposited into Uniswap V3 vaults
interface IUniV3Adapter is IAdapter {
  /// @notice Deposit assets into Uniswap V3 position
  /// @param user Address of user depositing assets
  /// @param data Used for data required to mint a Uniswap V3 position
  /// @return amount0 Amount of token0 deployed
  /// @return amount1 Amount of token1 deployed
  /// @dev User should approve this adapter to spend the appropriate amounts before calling
  function deployCapital(address user, bytes calldata data) external returns (uint256 amount0, uint256 amount1);

  /// @notice Return assets back to user that have been withdrawn from Uniswap V3 position
  /// @param to User to receive assets
  /// @param amount0 Amount of token0 user will receive
  /// @param amount1 Amount of token1 user will receive
  /// @param side ID of side
  /// @dev Should only be callable by the vault, and should only be called during the withdraw process
  function returnCapital(
    address to,
    uint256 amount0,
    uint256 amount1,
    uint256 side
  ) external;

  /// @notice Return asset back to user before vault starts
  /// @param to User to receive assets
  /// @param side ID of side
  /// @dev This is needed because fixed side depositors are entitled to any earnings generated before the vault starts
  function earlyReturnCapital(
    address to,
    uint256 side,
    bytes calldata data
  ) external returns (uint256, uint256);

  /// @notice Expected holdings, estimated due to lack of guarantees
  /// @return estimate0 Estimated amount of token0 holdings
  /// @return estimate1 Estimated amount of token1 holdings
  /// @dev Do not depend on these values to be guaranteed! In cases where exact holdings can be known, simply return holdings()
  function estimatedHoldings() external view returns (uint256 estimate0, uint256 estimate1);

  /// @notice Exact holdings values
  /// @return amount0 Exact amount of token0 holdings
  /// @return amount1 Exact amount of token1 holdings
  /// @dev If guaranteed values cannot be determined, an error should be thrown
  function holdings() external view returns (uint256 amount0, uint256 amount1);

  /// @notice Contract addresses of token0 and token1
  /// @return token0 Address of token0
  /// @return token1 Address of token1
  function assetAddresses() external view returns (address token0, address token1);

  /// @notice Get current earnings for token0 and token1
  /// @return token0 earnings
  /// @return token1 earnings
  function getEarnings() external view returns (uint256, uint256);

  /// @notice Collect earnings from Uniswap V3 position and finalize earnings balance
  /// @return Total earnings of token0 to be distributed to vault participants
  /// @return Total earnings of token1 to be distributed to vault participants
  /// @dev Gets called during first vault interaction after endTime
  function settleEarnings() external returns (uint256, uint256);

  /// @notice Removes liquidity from Uniswap V3 position
  /// @param to Receiver of liquidity
  /// @param data Data passed to Uniswap V3 needed to remove liquidity
  function removeLiquidity(address to, bytes calldata data) external returns (uint256, uint256);
}