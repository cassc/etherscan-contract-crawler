// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;
pragma abicoder v2;
/**
 * @title ILendingPoolCollateralManager
 * @author Aave
 * @notice Defines the actions involving management of collateral in the protocol.
 **/
interface ILendingPoolCollateralManager {
  /**
   * @dev Emitted when a borrower is liquidated
   * @param collateral The address of the collateral being liquidated
   * @param principal The address of the reserve
   * @param user The address of the user being liquidated
   * @param debtToCover The total amount liquidated
   * @param liquidatedCollateralAmount The amount of collateral being liquidated
   * @param liquidator The address of the liquidator
   * @param receiveVToken true if the liquidator wants to receive vTokens, false otherwise
   **/
  struct NFTLiquidationCallData{
    uint256 debtToCover;
    uint256 extraAssetToPay;
    uint256[] liquidatedCollateralTokenIds;
    uint256[] liquidatedCollateralAmounts;
    address liquidator;
    bool receiveNToken;
  }

  event NFTLiquidationCall(
    address indexed collateral,
    address indexed principal,
    address indexed user,
    bytes data
  );

  /**
   * @dev Emitted when a reserve is disabled as collateral for an user
   * @param reserve The address of the reserve
   * @param user The address of the user
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted when a reserve is enabled as collateral for an user
   * @param reserve The address of the reserve
   * @param user The address of the user
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

   /**
   * @dev Emitted when a reserve is disabled as collateral for an user
   * @param vault The address of the vault
   * @param user The address of the user
   **/
  event NFTVaultUsedAsCollateralDisabled(address indexed vault, address indexed user);

  /**
   * @dev Emitted when a reserve is enabled as collateral for an user
   * @param vault The address of the vault
   * @param user The address of the user
   **/
  event NFTVaultUsedAsCollateralEnabled(address indexed vault, address indexed user);

  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the vTokens
   * @param amount The amount deposited
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount
  );

  struct NFTLiquidationCallParameters {
    address collateralAsset;
    address debtAsset;
    address user;
    uint256[] tokenIds;
    uint256[] amounts;
    bool receiveNToken;
  }

  /**
   * @dev Users can invoke this function to liquidate an undercollateralized position.
   **/
  function nftLiquidationCall(
    NFTLiquidationCallParameters memory params
  ) external returns (uint256, string memory);
}