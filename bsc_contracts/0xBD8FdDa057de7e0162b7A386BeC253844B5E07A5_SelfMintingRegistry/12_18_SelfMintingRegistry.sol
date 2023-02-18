// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../interfaces/IFinder.sol';
import {SynthereumInterfaces} from '../Constants.sol';
import {SynthereumRegistry} from './Registry.sol';

/**
 * @title Register and track all the self-minting derivatives deployed
 */
contract SelfMintingRegistry is SynthereumRegistry {
  /**
   * @notice Constructs the SelfMintingRegistry contract
   * @param _synthereumFinder Synthereum finder contract
   */
  constructor(ISynthereumFinder _synthereumFinder)
    SynthereumRegistry(
      'SELF MINTING REGISTRY',
      _synthereumFinder,
      SynthereumInterfaces.SelfMintingRegistry
    )
  {}
}