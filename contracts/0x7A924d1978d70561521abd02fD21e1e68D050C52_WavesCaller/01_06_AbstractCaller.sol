// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./AllowedList.sol";
import "./Initializable.sol";
import "./Pausable.sol";

abstract contract AbstractCaller is AllowedList, Initializable, Pausable {
    uint16 public chainId;
    uint256 public nonce;
}