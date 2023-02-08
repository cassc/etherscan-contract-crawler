// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { Executable } from "../common/Executable.sol";
import { SafeERC20, IERC20 } from "../../libs/SafeERC20.sol";
import { SendTokenData } from "../../core/types/Common.sol";
import { UseStore, Read } from "./UseStore.sol";
import { OperationStorage } from "../../core/OperationStorage.sol";
import { SEND_TOKEN_ACTION, ETH } from "../../core/constants/Common.sol";
import "hardhat/console.sol";

/**
 * @title SendToken Action contract
 * @notice Transfer token from the calling contract to the destination address
 */
contract SendToken is Executable, UseStore {
  using SafeERC20 for IERC20;
  using Read for OperationStorage;

  constructor(address _registry) UseStore(_registry) {}

  /**
   * @param data Encoded calldata that conforms to the SendTokenData struct
   */
  function execute(bytes calldata data, uint8[] memory paramsMap) external payable override {
    SendTokenData memory send = parseInputs(data);
    send.amount = store().readUint(bytes32(send.amount), paramsMap[2], address(this));

    if (msg.value > 0) {
      payable(send.to).transfer(msg.value);
    } else {
      if (send.amount == type(uint256).max) {
        send.amount = IERC20(send.asset).balanceOf(address(this));
      }
      IERC20(send.asset).safeTransfer(send.to, send.amount);
    }

    emit Action(SEND_TOKEN_ACTION, bytes(abi.encode(send.amount)));
  }

  function parseInputs(bytes memory _callData) public pure returns (SendTokenData memory params) {
    return abi.decode(_callData, (SendTokenData));
  }
}