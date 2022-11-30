// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { Executable } from "../common/Executable.sol";
import { ServiceRegistry } from "../../core/ServiceRegistry.sol";
import { SafeERC20, IERC20 } from "../../libs/SafeERC20.sol";
import { IWETH } from "../../interfaces/tokens/IWETH.sol";
import { UnwrapEthData } from "../../core/types/Common.sol";
import { UseStore, Read } from "../../actions/common/UseStore.sol";
import { Swap } from "./Swap.sol";
import { WETH, SWAP } from "../../core/constants/Common.sol";
import { OperationStorage } from "../../core/OperationStorage.sol";
import { UNWRAP_ETH } from "../../core/constants/Common.sol";

/**
 * @title Unwrap ETH Action contract
 * @notice Unwraps WETH balances to ETH
 */
contract UnwrapEth is Executable, UseStore {
  using SafeERC20 for IERC20;
  using Read for OperationStorage;

  constructor(address _registry) UseStore(_registry) {}

  /**
   * @dev look at UseStore.sol to get additional info on paramsMapping
   * @param data Encoded calldata that conforms to the UnwrapEthData struct
   * @param paramsMap Maps operation storage values by index (index offset by +1) to execute calldata params
   */
  function execute(bytes calldata data, uint8[] memory paramsMap) external payable override {
    IWETH weth = IWETH(registry.getRegisteredService(WETH));

    UnwrapEthData memory unwrapData = parseInputs(data);

    unwrapData.amount = store().readUint(bytes32(unwrapData.amount), paramsMap[0], address(this));

    if (unwrapData.amount == type(uint256).max) {
      unwrapData.amount = weth.balanceOf(address(this));
    }

    weth.withdraw(unwrapData.amount);

    emit Action(UNWRAP_ETH, bytes(abi.encode(unwrapData.amount)));
  }

  function parseInputs(bytes memory _callData) public pure returns (UnwrapEthData memory params) {
    return abi.decode(_callData, (UnwrapEthData));
  }
}