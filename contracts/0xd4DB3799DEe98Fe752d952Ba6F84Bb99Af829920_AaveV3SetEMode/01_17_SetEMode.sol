// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { Executable } from "../../common/Executable.sol";
import { Write, UseStore } from "../../common/UseStore.sol";
import { OperationStorage } from "../../../core/OperationStorage.sol";
import { IVariableDebtToken } from "../../../interfaces/aave/IVariableDebtToken.sol";
import { IWETHGateway } from "../../../interfaces/aave/IWETHGateway.sol";
import { ILendingPool } from "../../../interfaces/aave/ILendingPool.sol";
import { SetEModeData } from "../../../core/types/Aave.sol";
import { AAVE_POOL, SETEMODE_V3_ACTION } from "../../../core/constants/Aave.sol";
import { IPoolV3 } from "../../../interfaces/aaveV3/IPoolV3.sol";

/**
 * @title SetEMode | AAVE V3 Action contract
 * @notice Sets the user's eMode on AAVE's lending pool
 */
contract AaveV3SetEMode is Executable, UseStore {
  using Write for OperationStorage;

  constructor(address _registry) UseStore(_registry) {}

  /**
   * @param data Encoded calldata that conforms to the SetEModeData struct
   */
  function execute(bytes calldata data, uint8[] memory) external payable override {
    SetEModeData memory emode = parseInputs(data);

    IPoolV3(registry.getRegisteredService(AAVE_POOL)).setUserEMode(emode.categoryId);

    store().write(bytes32(uint256(emode.categoryId)));

    emit Action(SETEMODE_V3_ACTION, abi.encode(emode.categoryId));
  }

  function parseInputs(bytes memory _callData) public pure returns (SetEModeData memory params) {
    return abi.decode(_callData, (SetEModeData));
  }
}