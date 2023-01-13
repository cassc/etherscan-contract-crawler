// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  IDeploymentSignature
} from '../../core/interfaces/IDeploymentSignature.sol';
import {
  ISynthereumCollateralWhitelist
} from '../../core/interfaces/ICollateralWhitelist.sol';
import {
  ISynthereumIdentifierWhitelist
} from '../../core/interfaces/IIdentifierWhitelist.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {SynthereumLiquidityPoolCreator} from './LiquidityPoolCreator.sol';
import {SynthereumLiquidityPool} from './LiquidityPool.sol';
import {FactoryConditions} from '../../common/FactoryConditions.sol';
import {
  ReentrancyGuard
} from '../../../@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract SynthereumLiquidityPoolFactory is
  IDeploymentSignature,
  ReentrancyGuard,
  FactoryConditions,
  SynthereumLiquidityPoolCreator
{
  //----------------------------------------
  // Storage
  //----------------------------------------

  bytes4 public immutable override deploymentSignature;

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Set synthereum finder
   * @param synthereumFinder Synthereum finder contract
   */
  constructor(address synthereumFinder)
    SynthereumLiquidityPoolCreator(synthereumFinder)
  {
    deploymentSignature = this.createPool.selector;
  }

  //----------------------------------------
  // Public functions
  //----------------------------------------

  /**
   * @notice Check if the sender is the deployer and deploy a pool
   * @param params input parameters of the pool
   * @return pool Deployed pool
   */
  function createPool(Params calldata params)
    public
    override
    nonReentrant
    onlyDeployer(synthereumFinder)
    returns (SynthereumLiquidityPool pool)
  {
    checkDeploymentConditions(
      synthereumFinder,
      params.collateralToken,
      params.priceIdentifier
    );
    pool = super.createPool(params);
  }
}