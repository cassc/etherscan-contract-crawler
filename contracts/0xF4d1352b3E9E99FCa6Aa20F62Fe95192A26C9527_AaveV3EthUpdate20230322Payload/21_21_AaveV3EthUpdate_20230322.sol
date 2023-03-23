// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
  AaveV3PayloadEthereum,
  IEngine,
  EngineFlags,
  AaveV3EthereumAssets
} from 'aave-helpers/v3-config-engine/AaveV3PayloadEthereum.sol';

contract AaveV3EthUpdate20230322Payload is AaveV3PayloadEthereum {
  function capsUpdates() public pure override returns (IEngine.CapsUpdate[] memory) {
    IEngine.CapsUpdate[] memory capsUpdate = new IEngine.CapsUpdate[](2);

    capsUpdate[0] = IEngine.CapsUpdate({
      asset: AaveV3EthereumAssets.wstETH_UNDERLYING,
      supplyCap: EngineFlags.KEEP_CURRENT,
      borrowCap: 6_000
    });

    capsUpdate[1] = IEngine.CapsUpdate({
      asset: AaveV3EthereumAssets.rETH_UNDERLYING,
      supplyCap: EngineFlags.KEEP_CURRENT,
      borrowCap: 2_400
    });

    return capsUpdate;
  }
}