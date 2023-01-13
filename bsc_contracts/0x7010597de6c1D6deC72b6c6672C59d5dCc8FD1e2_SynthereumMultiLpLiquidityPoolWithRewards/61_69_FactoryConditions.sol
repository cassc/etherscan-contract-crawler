// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IStandardERC20} from '../base/interfaces/IStandardERC20.sol';
import {ISynthereumFinder} from '../core/interfaces/IFinder.sol';
import {
  ISynthereumCollateralWhitelist
} from '../core/interfaces/ICollateralWhitelist.sol';
import {
  ISynthereumIdentifierWhitelist
} from '../core/interfaces/IIdentifierWhitelist.sol';
import {SynthereumInterfaces} from '../core/Constants.sol';

/** @title Contract to use iniside factories for checking deployment data
 */
contract FactoryConditions {
  /**
   * @notice Check if the sender is the deployer
   */
  modifier onlyDeployer(ISynthereumFinder _synthereumFinder) {
    address deployer =
      _synthereumFinder.getImplementationAddress(SynthereumInterfaces.Deployer);
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    _;
  }

  /**
   * @notice Check if the sender is the deployer and if identifier and collateral are supported
   * @param _synthereumFinder Synthereum finder
   * @param _collateralToken Collateral token to check if it's in the whithelist
   * @param _priceFeedIdentifier Identifier to check if it's in the whithelist
   */
  function checkDeploymentConditions(
    ISynthereumFinder _synthereumFinder,
    IStandardERC20 _collateralToken,
    bytes32 _priceFeedIdentifier
  ) internal view {
    address deployer =
      _synthereumFinder.getImplementationAddress(SynthereumInterfaces.Deployer);
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    ISynthereumCollateralWhitelist collateralWhitelist =
      ISynthereumCollateralWhitelist(
        _synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.CollateralWhitelist
        )
      );
    require(
      collateralWhitelist.isOnWhitelist(address(_collateralToken)),
      'Collateral not supported'
    );
    ISynthereumIdentifierWhitelist identifierWhitelist =
      ISynthereumIdentifierWhitelist(
        _synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.IdentifierWhitelist
        )
      );
    require(
      identifierWhitelist.isOnWhitelist(_priceFeedIdentifier),
      'Identifier not supported'
    );
  }
}