// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IPyth.sol";
import "./IWormhole.sol";

interface IPythWithGetters is IPyth {
  function wormhole() external view returns (IWormhole);

  function isValidDataSource(
    uint16 dataSourceChainId,
    bytes32 dataSourceEmitterAddress
  ) external view returns (bool);
}