// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {SwapTypes} from "./libraries/SwapTypes.sol";

contract EscrowStorage {
    CountersUpgradeable.Counter public swapId;
    mapping(uint256 => SwapTypes.Intent) public intents;
    mapping(uint256 => SwapTypes.Assets[]) public makers;
    mapping(uint256 => SwapTypes.Assets[]) public takers;
    mapping(address => bool) public erc20Allowlist;
    mapping(address => bool) public nftAllowlist;
    uint256 public fee;
    address payable public feeRecipient;
}