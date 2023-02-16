// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3ListingBase, IGenericV3ListingEngine} from './AaveV3ListingBase.sol';

/**
 * @dev Base smart contract for an Aave v3.0.1 listing (or other change of configs) on v3 Ethereum.
 * @author BGD Labs
 */
abstract contract AaveV3ListingEthereum is AaveV3ListingBase {
  constructor(IGenericV3ListingEngine listingEngine) AaveV3ListingBase(listingEngine) {}

  function getPoolContext()
    public
    pure
    override
    returns (IGenericV3ListingEngine.PoolContext memory)
  {
    return
      IGenericV3ListingEngine.PoolContext({networkName: 'Ethereum', networkAbbreviation: 'Eth'});
  }
}