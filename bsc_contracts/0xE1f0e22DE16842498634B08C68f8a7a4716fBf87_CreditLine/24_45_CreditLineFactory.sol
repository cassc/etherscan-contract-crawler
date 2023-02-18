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
import {CreditLineCreator} from './CreditLineCreator.sol';
import {CreditLine} from './CreditLine.sol';
import {FactoryConditions} from '../../common/FactoryConditions.sol';
import {
  ReentrancyGuard
} from '../../../@openzeppelin/contracts/security/ReentrancyGuard.sol';

/** @title Contract factory of self-minting derivatives
 */
contract CreditLineFactory is
  IDeploymentSignature,
  ReentrancyGuard,
  FactoryConditions,
  CreditLineCreator
{
  //----------------------------------------
  // Storage
  //----------------------------------------

  bytes4 public immutable override deploymentSignature;

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs the CreditLineFactory contract
   * @param _synthereumFinder Synthereum Finder address used to discover other contracts
   * @param _creditLineImplementation CreditLine implementation address
   */
  constructor(address _synthereumFinder, address _creditLineImplementation)
    CreditLineCreator(_synthereumFinder, _creditLineImplementation)
  {
    deploymentSignature = this.createSelfMintingDerivative.selector;
  }

  /**
   * @notice Check if the sender is the deployer and deploy a new creditLine contract
   * @param params is a `ConstructorParams` object from creditLine.
   * @return creditLine address of the deployed contract.
   */
  function createSelfMintingDerivative(Params calldata params)
    public
    override
    onlyDeployer(synthereumFinder)
    nonReentrant
    returns (CreditLine creditLine)
  {
    checkDeploymentConditions(
      synthereumFinder,
      params.collateralToken,
      params.priceFeedIdentifier
    );
    creditLine = super.createSelfMintingDerivative(params);
  }
}