// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IGoldfinchDesk
 * @author AlloyX
 */
interface IGoldfinchDesk {
  /**
   * @notice GoldFinch PoolToken Value in Value in term of USDC
   * @param _vaultAddress the vault address of which we calculate the balance
   */
  function getGoldFinchPoolTokenBalanceInUsdc(address _vaultAddress) external view returns (uint256);

  /**
   * @notice GoldFinch PoolToken Value in Value in term of USDC
   * @param _vaultAddress the vault address of which we calculate the balance
   * @param _poolAddress the pool address of which we calculate the balance
   * @param _tranche the tranche
   */
  function getGoldFinchPoolTokenBalanceInUsdcForPool(
    address _vaultAddress,
    address _poolAddress,
    uint256 _tranche
  ) external returns (uint256);

  /**
   * @notice Widthdraw GFI from pool token
   * @param _vaultAddress the vault address
   * @param _tokenIDs the IDs of token to sell
   */
  function withdrawGfiFromMultiplePoolTokens(address _vaultAddress, uint256[] calldata _tokenIDs) external;

  /**
   * @notice Fidu Value in Vault in term of USDC
   * @param _vaultAddress the vault address of which we calculate the balance
   */
  function getFiduBalanceInUsdc(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Purchase pool token to get pooltoken
   * @param _vaultAddress the vault address
   * @param _amount the amount of usdc to purchase by
   * @param _poolAddress the pool address to buy from
   * @param _tranche the tranch id
   */
  function purchasePoolToken(
    address _vaultAddress,
    uint256 _amount,
    address _poolAddress,
    uint256 _tranche
  ) external;

  /**
   * @notice Widthdraw from junior token to get repayments
   * @param _vaultAddress the vault address
   * @param _tokenID the ID of token to sell
   * @param _amount the amount to withdraw
   * @param _poolAddress the pool address to withdraw from
   */
  function withdrawFromJuniorToken(
    address _vaultAddress,
    uint256 _tokenID,
    uint256 _amount,
    address _poolAddress
  ) external;

  /**
   * @notice Purchase FIDU
   * @param _vaultAddress the vault address
   * @param _amount the amount of usdc to purchase by
   */
  function purchaseFIDU(address _vaultAddress, uint256 _amount) external;

  /**
   * @notice Sell senior token to redeem FIDU
   * @param _vaultAddress the vault address
   * @param _amount the amount of FIDU to sell
   */
  function sellFIDU(address _vaultAddress, uint256 _amount) external;
}