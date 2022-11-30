// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { Executable } from "../common/Executable.sol";
import { UseStore, Write, Read } from "../common/UseStore.sol";
import { OperationStorage } from "../../core/OperationStorage.sol";
import { IVariableDebtToken } from "../../interfaces/aave/IVariableDebtToken.sol";
import { IWETHGateway } from "../../interfaces/aave/IWETHGateway.sol";
import { PaybackData } from "../../core/types/Aave.sol";
import { ILendingPool } from "../../interfaces/aave/ILendingPool.sol";

import {
  AAVE_WETH_GATEWAY,
  AAVE_LENDING_POOL,
  PAYBACK_ACTION
} from "../../core/constants/Aave.sol";

/**
 * @title Payback | AAVE Action contract
 * @notice Pays back a specified amount to AAVE's lending pool
 */
contract AavePayback is Executable, UseStore {
  using Write for OperationStorage;
  using Read for OperationStorage;

  constructor(address _registry) UseStore(_registry) {}

  /**
   * @dev Look at UseStore.sol to get additional info on paramsMapping.
   * @dev The paybackAll flag - when passed - will signal the user wants to repay the full debt balance for a given asset
   * @param data Encoded calldata that conforms to the PaybackData struct
   * @param paramsMap Maps operation storage values by index (index offset by +1) to execute calldata params
   */
  function execute(bytes calldata data, uint8[] memory paramsMap) external payable override {
    PaybackData memory payback = abi.decode(data, (PaybackData));

    payback.amount = store().readUint(bytes32(payback.amount), paramsMap[1], address(this));

    ILendingPool(registry.getRegisteredService(AAVE_LENDING_POOL)).repay(
      payback.asset,
      payback.paybackAll ? type(uint256).max : payback.amount,
      2,
      address(this)
    );

    store().write(bytes32(payback.amount));
    emit Action(PAYBACK_ACTION, bytes(abi.encode(payback.amount)));
  }
}