// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface IRenBtcEthConverter {
  function convertToEth(uint256 minimumEthOut)
    external
    returns (uint256 actualEthOut);
}