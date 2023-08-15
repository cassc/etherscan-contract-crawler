// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEngine,EngineFlags,Rates} from 'aave-helpers/v3-config-engine/AaveV3PayloadBase.sol';
import {
  AaveV3PayloadEthereum,
  AaveV3EthereumAssets
} from 'aave-helpers/v3-config-engine/AaveV3PayloadEthereum.sol';

contract AaveV3EthereumUpdate20230710crvPayload is AaveV3PayloadEthereum {
  function capsUpdates() public pure override returns (IEngine.CapsUpdate[] memory) {
    IEngine.CapsUpdate[] memory capsUpdate = new IEngine.CapsUpdate[](1);

    capsUpdate[0] = IEngine.CapsUpdate({
      asset: AaveV3EthereumAssets.CRV_UNDERLYING,
      supplyCap: EngineFlags.KEEP_CURRENT,
      borrowCap: 3800000
    });

    return capsUpdate;
  }
}