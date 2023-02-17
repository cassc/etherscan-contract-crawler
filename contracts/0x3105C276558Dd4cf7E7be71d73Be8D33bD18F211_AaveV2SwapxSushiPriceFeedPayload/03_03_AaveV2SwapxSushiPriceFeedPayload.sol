// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';

/**
 * @title This proposal swaps the price feed for the xSushi on the v2 pool
 * @author BGD Labs
 * - Dicussion: https://governance.aave.com/t/bgd-swap-of-price-feed-of-xsushi-on-aave-v2-ethereum/11901
 */
contract AaveV2SwapxSushiPriceFeedPayload {
  address constant XSUSHI = AaveV2EthereumAssets.xSUSHI_UNDERLYING;
  address constant PRICE_FEED = 0xF05D9B6C08757EAcb1fbec18e36A1B7566a13DEB;

  function execute() external {
    address[] memory assets = new address[](1);
    address[] memory sources = new address[](1);

    assets[0] = XSUSHI;
    sources[0] = PRICE_FEED;

    AaveV2Ethereum.ORACLE.setAssetSources(assets, sources);
  }
}