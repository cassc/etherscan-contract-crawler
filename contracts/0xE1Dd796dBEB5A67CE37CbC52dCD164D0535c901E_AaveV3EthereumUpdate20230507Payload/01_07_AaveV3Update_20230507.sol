// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV2Avalanche,AaveV2AvalancheAssets} from 'aave-address-book/AaveV2Avalanche.sol';
import {AaveV2Ethereum,AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV2Polygon,AaveV2PolygonAssets} from 'aave-address-book/AaveV2Polygon.sol';
import {ILendingPoolConfigurator} from 'aave-address-book/AaveV2.sol';
import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';

struct RateUpdate {
  address asset;
  address interestRateStrategyAddress;
}

abstract contract AaveV2RateUpdatePayloadBase is IProposalGenericExecutor {
  function _poolConfigurator() internal virtual returns (ILendingPoolConfigurator);
  function _rateUpdates() internal virtual returns (RateUpdate[] memory);

  function execute() external {
    RateUpdate[] memory rateUpdates = _rateUpdates();
    ILendingPoolConfigurator poolConfigurator = _poolConfigurator();

    for (uint256 i = 0; i < rateUpdates.length; i++) {
      poolConfigurator.setReserveInterestRateStrategyAddress(
        rateUpdates[i].asset,
        rateUpdates[i].interestRateStrategyAddress
      );
    }
  }
}

contract AaveV3EthereumUpdate20230507Payload is AaveV2RateUpdatePayloadBase {
  function _poolConfigurator() internal override pure returns (ILendingPoolConfigurator) {
    return AaveV2Ethereum.POOL_CONFIGURATOR;
  }

  function _rateUpdates() internal override pure returns (RateUpdate[] memory) {
    RateUpdate[] memory rateUpdates = new RateUpdate[](5);

    rateUpdates[0] = RateUpdate({
      asset: AaveV2EthereumAssets.FRAX_UNDERLYING,
      interestRateStrategyAddress: 0x492dcEF1fc5253413fC5576B9522840a1A774DCe
    });
    rateUpdates[1] = RateUpdate({
      asset: AaveV2EthereumAssets.GUSD_UNDERLYING,
      interestRateStrategyAddress: 0x78Fe5d0427E669ba9F964C3495fF381a805a0487
    });
    rateUpdates[2] = RateUpdate({
      asset: AaveV2EthereumAssets.USDP_UNDERLYING,
      interestRateStrategyAddress: 0xaC63290BC16fBc33353b14f139cEf1c660ba56F0
    });
    rateUpdates[3] = RateUpdate({
      asset: AaveV2EthereumAssets.USDT_UNDERLYING,
      interestRateStrategyAddress: 0xF22c8255eA615b3Da6CA5CF5aeCc8956bfF07Aa8
    });
    rateUpdates[4] = RateUpdate({
      asset: AaveV2EthereumAssets.WBTC_UNDERLYING,
      interestRateStrategyAddress: 0x32f3A6134590fc2d9440663d35a2F0a6265F04c4
    });

    return rateUpdates;
  }
}

contract AaveV3AvalancheUpdate20230507Payload is AaveV2RateUpdatePayloadBase {
  function _poolConfigurator() internal override pure returns (ILendingPoolConfigurator) {
    return AaveV2Avalanche.POOL_CONFIGURATOR;
  }

  function _rateUpdates() internal override pure returns (RateUpdate[] memory) {
    RateUpdate[] memory rateUpdates = new RateUpdate[](3);

    rateUpdates[0] = RateUpdate({
      asset: AaveV2AvalancheAssets.USDTe_UNDERLYING,
      interestRateStrategyAddress: 0x78Fe5d0427E669ba9F964C3495fF381a805a0487
    });
    rateUpdates[1] = RateUpdate({
      asset: AaveV2AvalancheAssets.WAVAX_UNDERLYING,
      interestRateStrategyAddress: 0xaC63290BC16fBc33353b14f139cEf1c660ba56F0
    });
    rateUpdates[2] = RateUpdate({
      asset: AaveV2AvalancheAssets.WETHe_UNDERLYING,
      interestRateStrategyAddress: 0x32f3A6134590fc2d9440663d35a2F0a6265F04c4
    });

    return rateUpdates;
  }
}

contract AaveV3PolygonUpdate20230507Payload is AaveV2RateUpdatePayloadBase {
  function _poolConfigurator() internal override pure returns (ILendingPoolConfigurator) {
    return AaveV2Polygon.POOL_CONFIGURATOR;
  }

  function _rateUpdates() internal override pure returns (RateUpdate[] memory) {
    RateUpdate[] memory rateUpdates = new RateUpdate[](4);

    rateUpdates[0] = RateUpdate({
      asset: AaveV2PolygonAssets.USDT_UNDERLYING,
      interestRateStrategyAddress: 0xF4d1352b3E9E99FCa6Aa20F62Fe95192A26C9527
    });
    rateUpdates[1] = RateUpdate({
      asset: AaveV2PolygonAssets.WBTC_UNDERLYING,
      interestRateStrategyAddress: 0x142DCAEC322aAA25141B2597bf348487aDBd596d
    });
    rateUpdates[2] = RateUpdate({
      asset: AaveV2PolygonAssets.WETH_UNDERLYING,
      interestRateStrategyAddress: 0x492dcEF1fc5253413fC5576B9522840a1A774DCe
    });
    rateUpdates[3] = RateUpdate({
      asset: AaveV2PolygonAssets.WMATIC_UNDERLYING,
      interestRateStrategyAddress: 0x78Fe5d0427E669ba9F964C3495fF381a805a0487
    });

    return rateUpdates;
  }
}