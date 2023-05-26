// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3PayloadEthereum, IEngine, EngineFlags} from 'aave-helpers/v3-config-engine/AaveV3PayloadEthereum.sol';

/**
 * @title This proposal activate rETH emode on eth V3 Pool.
 * @author @marczeller - Aave-Chan Initiative
 * - Snapshot: https://snapshot.org/#/aave.eth/proposal/0x39c155cd6e9e05c123e520283b5c41e96a58b21af150bac8f3272a17e241ef50
 * - Discussion: https://governance.aave.com/t/arfc-activate-emode-for-reth-aave-ethereum-v3-pool/13034
 */
contract AaveV3ETHrETHEmode_20230522 is AaveV3PayloadEthereum {
  function collateralsUpdates() public pure override returns (IEngine.CollateralUpdate[] memory) {
    IEngine.CollateralUpdate[] memory collateralUpdate = new IEngine.CollateralUpdate[](1);

    collateralUpdate[0] = IEngine.CollateralUpdate({
      asset: AaveV3EthereumAssets.rETH_UNDERLYING,
      ltv: EngineFlags.KEEP_CURRENT,
      liqThreshold: EngineFlags.KEEP_CURRENT,
      liqBonus: EngineFlags.KEEP_CURRENT,
      debtCeiling: EngineFlags.KEEP_CURRENT,
      liqProtocolFee: EngineFlags.KEEP_CURRENT,
      eModeCategory: 1
    });
    return collateralUpdate;
  }
}