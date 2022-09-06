// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface ILidoOracle {
  function getLastCompletedReportDelta()
    external
    view
    returns (
      uint256 postTotalPooledEther,
      uint256 preTotalPooledEther,
      uint256 timeElapsed
    );
}