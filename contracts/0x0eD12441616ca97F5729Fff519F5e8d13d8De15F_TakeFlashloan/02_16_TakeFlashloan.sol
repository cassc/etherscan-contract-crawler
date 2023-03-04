// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { Executable } from "../common/Executable.sol";
import { ServiceRegistry } from "../../core/ServiceRegistry.sol";
import { IERC3156FlashBorrower } from "../../interfaces/flashloan/IERC3156FlashBorrower.sol";
import { IERC3156FlashLender } from "../../interfaces/flashloan/IERC3156FlashLender.sol";
import { FlashloanData } from "../../core/types/Common.sol";
import { OPERATION_EXECUTOR, DAI, CHAINLOG_VIEWER, TAKE_FLASH_LOAN_ACTION } from "../../core/constants/Common.sol";
import { MCD_FLASH } from "../../core/constants/Maker.sol";
import { ProxyPermission } from "../../libs/DS/ProxyPermission.sol";
import { ChainLogView } from "../../core/views/ChainLogView.sol";

/**
 * @title TakeFlashloan Action contract
 * @notice Executes a sequence of Actions after flashloaning funds
 */
contract TakeFlashloan is Executable, ProxyPermission {
  ServiceRegistry internal immutable registry;
  address internal immutable dai;

  constructor(ServiceRegistry _registry, address _dai) {
    registry = _registry;
    dai = _dai;
  }

  /**
   * @dev When the Flashloan lender calls back the Operation Executor we may need to re-establish the calling context.
   * @dev The isProxyFlashloan flag is used to give the Operation Executor temporary authority to call the execute method on a user"s proxy. Refers to any proxy wallet (DSProxy or DPMProxy at time of writing)
   * @dev isDPMProxy flag switches between regular DSPRoxy and DPMProxy
   * @param data Encoded calldata that conforms to the FlashloanData struct
   */
  function execute(bytes calldata data, uint8[] memory) external payable override {
    FlashloanData memory flData = parseInputs(data);

    address operationExecutorAddress = registry.getRegisteredService(OPERATION_EXECUTOR);

    if (flData.isProxyFlashloan) {
      givePermission(flData.isDPMProxy, operationExecutorAddress);
    }

    ChainLogView chainlogView = ChainLogView(registry.getRegisteredService(CHAINLOG_VIEWER));

    IERC3156FlashLender(chainlogView.getServiceAddress(MCD_FLASH)).flashLoan(
      IERC3156FlashBorrower(operationExecutorAddress),
      dai,
      flData.amount,
      data
    );

    if (flData.isProxyFlashloan) {
      removePermission(flData.isDPMProxy, operationExecutorAddress);
    }

    emit Action(TAKE_FLASH_LOAN_ACTION, bytes(abi.encode(flData.amount)));
  }

  function parseInputs(bytes memory _callData) public pure returns (FlashloanData memory params) {
    return abi.decode(_callData, (FlashloanData));
  }
}