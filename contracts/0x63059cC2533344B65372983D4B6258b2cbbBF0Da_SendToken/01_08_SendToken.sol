// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { Executable } from "../common/Executable.sol";
import { SafeERC20, IERC20 } from "../../libs/SafeERC20.sol";
import { SendTokenData } from "../../core/types/Common.sol";
import { SEND_TOKEN_ACTION } from "../../core/constants/Common.sol";

/**
 * @title SendToken Action contract
 * @notice Transfer token from the calling contract to the destination address
 */
contract SendToken is Executable {
  using SafeERC20 for IERC20;

  /**
   * @param data Encoded calldata that conforms to the SendTokenData struct
   */
  function execute(bytes calldata data, uint8[] memory) external payable override {
    SendTokenData memory send = parseInputs(data);

    if (msg.value > 0) {
      payable(send.to).transfer(send.amount);
    } else {
      IERC20(send.asset).safeTransfer(send.to, send.amount);
    }

    emit Action(SEND_TOKEN_ACTION, bytes(abi.encode(send.amount)));
  }

  function parseInputs(bytes memory _callData) public pure returns (SendTokenData memory params) {
    return abi.decode(_callData, (SendTokenData));
  }
}