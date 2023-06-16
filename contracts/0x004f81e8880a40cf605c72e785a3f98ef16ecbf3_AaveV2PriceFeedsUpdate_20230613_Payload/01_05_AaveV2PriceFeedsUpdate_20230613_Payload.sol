// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';

/**
 * @title stETH Price Feed update
 * @author BGD Labs
 * @notice Change stETH price feed on the Aave Ethereum v2 pool.
 * Governance Forum Post: https://governance.aave.com/t/bgd-operational-oracles-update/13213/9
 */
contract AaveV2PriceFeedsUpdate_20230613_Payload {
  // stETH / ETH price adapter
  address public constant STETH_ADAPTER = 0xADE6CBA6c45aa8E9d0337cAc3D2619eabc39D901;

  function execute() external {
    address[] memory assets = new address[](1);
    address[] memory sources = new address[](1);

    assets[0] = AaveV2EthereumAssets.stETH_UNDERLYING;
    sources[0] = STETH_ADAPTER;

    AaveV2Ethereum.ORACLE.setAssetSources(assets, sources);
  }
}