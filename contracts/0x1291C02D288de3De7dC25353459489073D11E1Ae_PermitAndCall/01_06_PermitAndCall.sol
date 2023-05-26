// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {
  IERC2612,
  IERC20PermitAllowed
} from "./interfaces/IERC2612.sol";
import {IERC20MetaTransaction} from "./interfaces/INativeMetaTransaction.sol";
import {SafePermit} from "./lib/SafePermit.sol";
import {Revert} from "./lib/Revert.sol";

contract PermitAndCall {
  using SafePermit for IERC2612;
  using SafePermit for IERC20PermitAllowed;
  using SafePermit for IERC20MetaTransaction;
  using Revert for bytes;

  address payable public constant target = payable(0xDef1C0ded9bec7F1a1670819833240f027b25EfF);

  function permitAndCall(
    IERC2612 token,
    address owner,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bytes calldata data
  ) external payable returns (bytes memory) {
    token.safePermit(owner, target, amount, deadline, v, r, s);
    (bool success, bytes memory returndata) = target.call{value: msg.value}(data);
    if (!success) {
      returndata.revert_();
    }
    return returndata;
  }

  function permitAndCall(
    IERC20PermitAllowed token,
    address owner,
    uint256 nonce,
    uint256 deadline,
    bool allowed,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bytes calldata data
  ) external payable returns (bytes memory) {
    token.safePermit(owner, target, nonce, deadline, allowed, v, r, s);
    (bool success, bytes memory returndata) = target.call{value: msg.value}(data);
    if (!success) {
      returndata.revert_();
    }
    return returndata;
  }

  function permitAndCall(
    IERC20MetaTransaction token,
    address owner,
    uint256 amount,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bytes calldata data
  ) external payable returns (bytes memory) {
    token.safePermit(owner, target, amount, v, r, s);
    (bool success, bytes memory returndata) = target.call{value: msg.value}(data);
    if (!success) {
      returndata.revert_();
    }
    return returndata;
  }
}