// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {NFTVaultConfiguration} from '../configuration/NFTVaultConfiguration.sol';
import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title NFTVaultLogic library
 * @author Vinci
 * @notice Implements the logic to update the vault state
 */
library NFTVaultLogic {
  using NFTVaultLogic for DataTypes.NFTVaultData;
  using NFTVaultConfiguration for DataTypes.NFTVaultConfigurationMap;

  /**
   * @dev Initializes a reserve
   * @param reserve The reserve object
   * @param nTokenAddress The address of the overlying vtoken contract
   **/
  function init(
    DataTypes.NFTVaultData storage reserve,
    address nTokenAddress,
    address nftEligibility
  ) external {
    require(reserve.nTokenAddress == address(0), Errors.NL_VAULT_ALREADY_INITIALIZED);
    reserve.nTokenAddress = nTokenAddress;
    reserve.nftEligibility = nftEligibility;
  }

}