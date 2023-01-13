// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ISynthereumLiquidityPoolInteraction {
  /**
   * @notice Called by a source Pool's `exchange` function to mint destination tokens
   * @notice This functon can be called only by a pool registered in the PoolRegister contract
   * @param collateralAmount The amount of collateral to use from the source Pool
   * @param numTokens The number of new tokens to mint
   * @param recipient Recipient to which send synthetic token minted
   */
  function exchangeMint(
    uint256 collateralAmount,
    uint256 numTokens,
    address recipient
  ) external;

  /**
   * @notice Returns price identifier of the pool
   * @return identifier Price identifier
   */
  function getPriceFeedIdentifier() external view returns (bytes32 identifier);

  /**
   * @notice Return overcollateralization percentage from the storage
   * @return Overcollateralization percentage
   */
  function overCollateralization() external view returns (uint256);

  /**
   * @notice Returns the total amount of liquidity deposited in the pool, but nut used as collateral
   * @return Total available liquidity
   */
  function totalAvailableLiquidity() external view returns (uint256);
}