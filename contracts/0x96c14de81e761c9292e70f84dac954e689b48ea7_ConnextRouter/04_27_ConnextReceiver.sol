// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title ConnextReceiver
 *
 * @author Fujidao Labs
 *
 * @notice A proxy contract that receive the XReceive call from connext to
 * allow assets to be safely pulled in {ConnextRouter.sol}
 */

import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IXReceiver} from "../interfaces/connext/IConnext.sol";
import {ConnextRouter} from "./ConnextRouter.sol";

contract ConnextReceiver is IXReceiver {
  using SafeERC20 for IERC20;

  error ConnextReceiver__xReceive_notReceivedAssetBalance();

  ConnextRouter public immutable connextRouter;

  /**
   * @notice Constructor that initializes ConnextReceiver
   */
  constructor(address connextRouter_) {
    // No need to check address(0) since this contract is deployed within {ConnextRouter.sol}
    connextRouter = ConnextRouter(payable(connextRouter_));
  }

  function xReceive(
    bytes32 transferId,
    uint256 amount,
    address asset,
    address originSender,
    uint32 originDomain,
    bytes memory callData
  )
    external
    returns (bytes memory)
  {
    if (amount > 0) {
      uint256 balance = IERC20(asset).balanceOf(address(this));
      if (balance < amount) {
        revert ConnextReceiver__xReceive_notReceivedAssetBalance();
      }
      IERC20(asset).safeIncreaseAllowance(address(connextRouter), amount);
    }

    return connextRouter.xReceive(transferId, amount, asset, originSender, originDomain, callData);
  }
}