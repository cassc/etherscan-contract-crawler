// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { Executable } from "../common/Executable.sol";
import { UseStore, Write, Read } from "../common/UseStore.sol";
import { OperationStorage } from "../../core/OperationStorage.sol";
import { ILendingPool } from "../../interfaces/aave/ILendingPool.sol";
import { DepositData } from "../../core/types/Aave.sol";
import { SafeMath } from "../../libs/SafeMath.sol";
import { SafeERC20, IERC20 } from "../../libs/SafeERC20.sol";
import { AAVE_LENDING_POOL, DEPOSIT_ACTION } from "../../core/constants/Aave.sol";

/**
 * @title Deposit | AAVE Action contract
 * @notice Deposits the specified asset as collateral on AAVE's lending pool
 */
contract AaveDeposit is Executable, UseStore {
  using Write for OperationStorage;
  using Read for OperationStorage;
  using SafeMath for uint256;

  constructor(address _registry) UseStore(_registry) {}

  /**
   * @dev Look at UseStore.sol to get additional info on paramsMapping
   * @param data Encoded calldata that conforms to the DepositData struct
   * @param paramsMap Maps operation storage values by index (index offset by +1) to execute calldata params
   */
  function execute(bytes calldata data, uint8[] memory paramsMap) external payable override {
    DepositData memory deposit = parseInputs(data);

    uint256 mappedDepositAmount = store().readUint(
      bytes32(deposit.amount),
      paramsMap[1],
      address(this)
    );

    uint256 actualDepositAmount = deposit.sumAmounts
      ? mappedDepositAmount.add(deposit.amount)
      : mappedDepositAmount;

    ILendingPool(registry.getRegisteredService(AAVE_LENDING_POOL)).deposit(
      deposit.asset,
      actualDepositAmount,
      address(this),
      0
    );

    if (deposit.setAsCollateral) {
      ILendingPool(registry.getRegisteredService(AAVE_LENDING_POOL)).setUserUseReserveAsCollateral(
        deposit.asset,
        true
      );
    }

    store().write(bytes32(actualDepositAmount));
    emit Action(DEPOSIT_ACTION, bytes(abi.encode(actualDepositAmount)));
  }

  function parseInputs(bytes memory _callData) public pure returns (DepositData memory params) {
    return abi.decode(_callData, (DepositData));
  }
}