// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3PayloadEthereum, IEngine} from 'aave-helpers/v3-config-engine/AaveV3PayloadEthereum.sol';

/**
 * @title wstETH Price Feed update
 * @author BGD Labs
 * @notice Change wstETH price feed on the Aave Ethereum v3 pool.
 * - Governance Forum Post: https://governance.aave.com/t/bgd-operational-oracles-update/13213/9
 */
contract AaveV3PriceFeedsUpdate_20230613_Payload is AaveV3PayloadEthereum {
  // WSTETH / ETH / USD price adapter
  address public constant WSTETH_ADAPTER = 0x8B6851156023f4f5A66F68BEA80851c3D905Ac93;

  function priceFeedsUpdates() public pure override returns (IEngine.PriceFeedUpdate[] memory) {
    IEngine.PriceFeedUpdate[] memory priceFeedUpdate = new IEngine.PriceFeedUpdate[](1);
    priceFeedUpdate[0] = IEngine.PriceFeedUpdate({
      asset: AaveV3EthereumAssets.wstETH_UNDERLYING,
      priceFeed: WSTETH_ADAPTER
    });

    return priceFeedUpdate;
  }
}