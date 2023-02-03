// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {TestSeniorPool} from "./TestSeniorPool.sol";
import {IERC20} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Contract that can be used as a middle man between an EOA and SeniorPool. Useful for
 * testing different authorization combos, e.g. EOA has a UID and has ERC1155-approved this
 * contract.
 */
contract TestSeniorPoolCaller {
  TestSeniorPool private immutable seniorPool;

  constructor(TestSeniorPool _seniorPool, address usdc, address fidu) public {
    seniorPool = _seniorPool;
    IERC20(usdc).approve(address(_seniorPool), type(uint256).max);
    IERC20(fidu).approve(address(_seniorPool), type(uint256).max);
  }

  function deposit(uint256 usdcAmount) public returns (uint256) {
    return seniorPool.deposit(usdcAmount);
  }

  function requestWithdrawal(uint256 fiduAmount) public returns (uint256) {
    return seniorPool.requestWithdrawal(fiduAmount);
  }

  function addToWithdrawalRequest(uint256 fiduAmount, uint256 tokenId) public {
    seniorPool.addToWithdrawalRequest(fiduAmount, tokenId);
  }

  function cancelWithdrawalRequest(uint256 tokenId) public {
    seniorPool.cancelWithdrawalRequest(tokenId);
  }

  function claimWithdrawalRequest(uint256 tokenId) public returns (uint256) {
    return seniorPool.claimWithdrawalRequest(tokenId);
  }
}