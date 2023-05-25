// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import "../MonetaryPolicyV1.sol";

contract MonetaryPolicyV1Harness is MonetaryPolicyV1 {
  uint256 public blockNumber;

  constructor(address _governance, address _ethUsdOracle)
    MonetaryPolicyV1(_governance, _ethUsdOracle)
  {}

  function _blockNumber() internal view override returns (uint256) {
    return blockNumber;
  }

  function __setBlock(uint256 _number) external {
    blockNumber = _number;
  }
}