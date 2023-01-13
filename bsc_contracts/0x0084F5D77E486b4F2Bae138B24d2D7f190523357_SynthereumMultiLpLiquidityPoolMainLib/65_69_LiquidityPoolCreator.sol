// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableTokenFactory
} from '../../tokens/factories/interfaces/IMintableBurnableTokenFactory.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumLiquidityPoolStorage
} from './interfaces/ILiquidityPoolStorage.sol';
import {
  IMintableBurnableERC20
} from '../../tokens/interfaces/IMintableBurnableERC20.sol';
import {
  BaseControlledMintableBurnableERC20
} from '../../tokens/BaseControlledMintableBurnableERC20.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {SynthereumLiquidityPool} from './LiquidityPool.sol';

contract SynthereumLiquidityPoolCreator {
  struct Params {
    IStandardERC20 collateralToken;
    string syntheticName;
    string syntheticSymbol;
    address syntheticToken;
    ISynthereumLiquidityPoolStorage.Roles roles;
    uint256 overCollateralization;
    ISynthereumLiquidityPoolStorage.FeeData feeData;
    bytes32 priceIdentifier;
    uint256 collateralRequirement;
    uint256 liquidationReward;
    uint8 version;
  }

  // Address of Synthereum Finder
  ISynthereumFinder public immutable synthereumFinder;

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs the Pool contract.
   * @param _synthereumFinder Synthereum Finder address used to discover other contracts
   */
  constructor(address _synthereumFinder) {
    synthereumFinder = ISynthereumFinder(_synthereumFinder);
  }

  //----------------------------------------
  // Public functions
  //----------------------------------------

  /**
   * @notice Creates an instance of the pool
   * @param params is a `ConstructorParams` object from LiquidityPool.
   * @return pool address of the deployed pool contract.
   */
  function createPool(Params calldata params)
    public
    virtual
    returns (SynthereumLiquidityPool pool)
  {
    require(bytes(params.syntheticName).length != 0, 'Missing synthetic name');
    require(
      bytes(params.syntheticSymbol).length != 0,
      'Missing synthetic symbol'
    );

    if (params.syntheticToken == address(0)) {
      IMintableBurnableTokenFactory tokenFactory =
        IMintableBurnableTokenFactory(
          ISynthereumFinder(synthereumFinder).getImplementationAddress(
            SynthereumInterfaces.TokenFactory
          )
        );
      BaseControlledMintableBurnableERC20 tokenCurrency =
        tokenFactory.createToken(
          params.syntheticName,
          params.syntheticSymbol,
          18
        );
      pool = new SynthereumLiquidityPool(_convertParams(params, tokenCurrency));
      // Give permissions to new pool contract and then hand over ownership.
      tokenCurrency.addMinter(address(pool));
      tokenCurrency.addBurner(address(pool));
      tokenCurrency.addAdmin(
        synthereumFinder.getImplementationAddress(SynthereumInterfaces.Manager)
      );
      tokenCurrency.renounceAdmin();
    } else {
      BaseControlledMintableBurnableERC20 tokenCurrency =
        BaseControlledMintableBurnableERC20(params.syntheticToken);
      require(
        keccak256(abi.encodePacked(tokenCurrency.name())) ==
          keccak256(abi.encodePacked(params.syntheticName)),
        'Wrong synthetic token name'
      );
      require(
        keccak256(abi.encodePacked(tokenCurrency.symbol())) ==
          keccak256(abi.encodePacked(params.syntheticSymbol)),
        'Wrong synthetic token symbol'
      );
      pool = new SynthereumLiquidityPool(_convertParams(params, tokenCurrency));
    }
    return pool;
  }

  // Converts createPool params to constructor params.
  function _convertParams(
    Params memory params,
    BaseControlledMintableBurnableERC20 tokenCurrency
  )
    internal
    view
    returns (SynthereumLiquidityPool.ConstructorParams memory constructorParams)
  {
    require(params.roles.admin != address(0), 'Admin cannot be 0x00');
    constructorParams.finder = synthereumFinder;
    constructorParams.version = params.version;
    constructorParams.collateralToken = params.collateralToken;
    constructorParams.syntheticToken = IMintableBurnableERC20(
      address(tokenCurrency)
    );
    constructorParams.roles = params.roles;
    constructorParams.overCollateralization = params.overCollateralization;
    constructorParams.feeData = params.feeData;
    constructorParams.priceIdentifier = params.priceIdentifier;
    constructorParams.collateralRequirement = params.collateralRequirement;
    constructorParams.liquidationReward = params.liquidationReward;
  }
}