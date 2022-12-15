pragma solidity ^0.8.10;

import {FintochPool} from './FintochPool.sol';
import {IInvestmentEarnings} from '../../interfaces/IInvestmentEarnings.sol';
import {IL2Pool} from '../../interfaces/IL2Pool.sol';
import {CalldataLogic} from '../libraries/logic/CalldataLogic.sol';

/**
 * @title L2Pool
 *
 * @notice Calldata optimized extension of the Pool contract allowing users to pass compact calldata representation
 * to reduce transaction costs on rollups.
 */
abstract contract L2Pool is FintochPool, IL2Pool {
  /**
   * @dev Constructor.
   */
  constructor(
    IInvestmentEarnings investmentEarnings,
    address srcToken,
    address[] memory _owners,
    uint _required
  ) FintochPool(investmentEarnings, srcToken, _owners, _required) {
    // Intentionally left blank
  }

}