// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title AaveEModeHelper
 *
 * @author Fujidao Labs
 *
 * @notice Helper contract that aids to determine config Ids if a collateral
 * debt pair is eligible for Aave-v3 efficiency mode (e-mode).
 *
 * @dev This helper contract needs to be set-up.
 * To find the existing emode configuration Ids use
 * query schema:
 * {
 *  emodeCategories{
 *    id
 *      label
 *   }
 * }
 *
 * Refer to each chain subgraphs site at:
 * https://github.com/aave/protocol-subgraphs#production-networks
 */

import {IV3Pool} from "../interfaces/aaveV3/IV3Pool.sol";
import {SystemAccessControl, IChief} from "../access/SystemAccessControl.sol";

contract AaveEModeHelper is SystemAccessControl {
  // Events
  event EmodeConfigSet(address indexed asset, address indexed debt, uint8 configId);

  // Custom errors
  error AaveEModeHelper_constructor_addressZero();
  error AaveEModeHelper_setEModeConfig_arrayDiscrepancy();

  // collateral asset => debt asset => configId
  mapping(address => mapping(address => uint8)) internal _eModeConfigIds;

  constructor(address chief_) {
    if (chief_ == address(0)) revert AaveEModeHelper_constructor_addressZero();
    __SystemAccessControl_init(chief_);
  }

  /**
   * @notice Returns de config Id if any for asset-debt pair in AaveV3 pool.
   * It none, returns zero.
   *
   * @param asset erc-20 address of collateral
   * @param debt erc-20 address of debt asset
   */
  function getEModeConfigIds(address asset, address debt) external view returns (uint8 id) {
    return _eModeConfigIds[asset][debt];
  }

  /**
   * @notice Sets the configIds for an array of `assets` and `debts`
   *
   * @param assets erc-20 address array to set e-mode config
   * @param debts erc-20 address array corresponding asset in mapping
   * @param configIds from aaveV3 (refer to this contract title block)
   */
  function setEModeConfig(
    address[] calldata assets,
    address[] calldata debts,
    uint8[] calldata configIds
  )
    external
    onlyTimelock
  {
    uint256 len = assets.length;
    if (len != debts.length || len != configIds.length) {
      revert AaveEModeHelper_setEModeConfig_arrayDiscrepancy();
    }

    for (uint256 i = 0; i < len;) {
      if (assets[i] != address(0) && debts[i] != address(0)) {
        _eModeConfigIds[assets[i]][debts[i]] = configIds[i];

        emit EmodeConfigSet(assets[i], debts[i], configIds[i]);
      }
      unchecked {
        ++i;
      }
    }
  }
}