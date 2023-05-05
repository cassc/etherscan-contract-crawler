// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface INetworkTreasury {
  /**
   * @dev This should return an estimate of the total value of the buffer in DAI.
   * Keeper Networks should convert non-DAI assets to DAI value via an oracle.
   *
   * Ex) If the network bulk trades DAI for ETH then the value of the ETH sitting
   * in the treasury should count towards this buffer size.
   */
  function getBufferSize() external view returns (uint256);
}