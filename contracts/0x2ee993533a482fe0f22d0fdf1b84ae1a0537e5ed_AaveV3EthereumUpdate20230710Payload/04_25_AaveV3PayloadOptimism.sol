// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Optimism, AaveV3OptimismAssets} from 'aave-address-book/AaveV3Optimism.sol';
import './AaveV3PayloadBase.sol';

/**
 * @dev Base smart contract for an Aave v3.0.1 (compatible with 3.0.0) listing on v3 Optimism.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadOptimism is
  AaveV3PayloadBase(IEngine(AaveV3Optimism.LISTING_ENGINE))
{
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Optimism', networkAbbreviation: 'Opt'});
  }
}