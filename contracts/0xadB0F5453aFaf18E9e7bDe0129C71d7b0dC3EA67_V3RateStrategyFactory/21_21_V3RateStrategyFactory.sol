// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolAddressesProvider, IPool} from 'aave-address-book/AaveV3.sol';
import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';
import {DefaultReserveInterestRateStrategy} from 'aave-v3-core/contracts/protocol/pool/DefaultReserveInterestRateStrategy.sol';
import './IV3RateStrategyFactory.sol';

/**
 * @title V3RateStrategyFactory
 * @notice Factory contract to create and keep record of Aave v3 rate strategy contracts
 * @dev Associated to an specific Aave v3 Pool, via its addresses provider
 * @author BGD labs
 */
contract V3RateStrategyFactory is Initializable, IV3RateStrategyFactory {
  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  mapping(bytes32 => address) internal _strategyByParamsHash;
  address[] internal _strategies;

  constructor(IPoolAddressesProvider addressesProvider) Initializable() {
    ADDRESSES_PROVIDER = addressesProvider;
  }

  /// @dev Passing a arbitrary list of rate strategies to be registered as if they would have been deployed
  /// from this factory, as they share exactly the same code
  function initialize(IDefaultInterestRateStrategy[] memory liveStrategies) external initializer {
    for (uint256 i = 0; i < liveStrategies.length; i++) {
      RateStrategyParams memory params = getStrategyData(liveStrategies[i]);

      bytes32 hashedParams = strategyHashFromParams(params);

      _strategyByParamsHash[hashedParams] = address(liveStrategies[i]);
      _strategies.push(address(liveStrategies[i]));

      emit RateStrategyCreated(address(liveStrategies[i]), hashedParams, params);
    }
  }

  ///@inheritdoc IV3RateStrategyFactory
  function createStrategies(RateStrategyParams[] memory params) public returns (address[] memory) {
    address[] memory strategies = new address[](params.length);
    for (uint256 i = 0; i < params.length; i++) {
      bytes32 strategyHashedParams = strategyHashFromParams(params[i]);

      address cachedStrategy = _strategyByParamsHash[strategyHashedParams];

      if (cachedStrategy == address(0)) {
        cachedStrategy = address(
          new DefaultReserveInterestRateStrategy(
            ADDRESSES_PROVIDER,
            params[i].optimalUsageRatio,
            params[i].baseVariableBorrowRate,
            params[i].variableRateSlope1,
            params[i].variableRateSlope2,
            params[i].stableRateSlope1,
            params[i].stableRateSlope2,
            params[i].baseStableRateOffset,
            params[i].stableRateExcessOffset,
            params[i].optimalStableToTotalDebtRatio
          )
        );
        _strategyByParamsHash[strategyHashedParams] = cachedStrategy;
        _strategies.push(cachedStrategy);

        emit RateStrategyCreated(cachedStrategy, strategyHashedParams, params[i]);
      }

      strategies[i] = cachedStrategy;
    }

    return strategies;
  }

  ///@inheritdoc IV3RateStrategyFactory
  function strategyHashFromParams(RateStrategyParams memory params) public pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          params.optimalUsageRatio,
          params.baseVariableBorrowRate,
          params.variableRateSlope1,
          params.variableRateSlope2,
          params.stableRateSlope1,
          params.stableRateSlope2,
          params.baseStableRateOffset,
          params.stableRateExcessOffset,
          params.optimalStableToTotalDebtRatio
        )
      );
  }

  ///@inheritdoc IV3RateStrategyFactory
  function getAllStrategies() external view returns (address[] memory) {
    return _strategies;
  }

  ///@inheritdoc IV3RateStrategyFactory
  function getStrategyByParams(RateStrategyParams memory params) external view returns (address) {
    return _strategyByParamsHash[strategyHashFromParams(params)];
  }

  ///@inheritdoc IV3RateStrategyFactory
  function getStrategyDataOfAsset(address asset) external view returns (RateStrategyParams memory) {
    RateStrategyParams memory params;

    IDefaultInterestRateStrategy strategy = IDefaultInterestRateStrategy(
      IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(asset).interestRateStrategyAddress
    );

    if (address(strategy) != address(0)) {
      params = getStrategyData(strategy);
    }

    return params;
  }

  ///@inheritdoc IV3RateStrategyFactory
  function getStrategyData(IDefaultInterestRateStrategy strategy)
    public
    view
    returns (RateStrategyParams memory)
  {
    return
      RateStrategyParams({
        optimalUsageRatio: strategy.OPTIMAL_USAGE_RATIO(),
        baseVariableBorrowRate: strategy.getBaseVariableBorrowRate(),
        variableRateSlope1: strategy.getVariableRateSlope1(),
        variableRateSlope2: strategy.getVariableRateSlope2(),
        stableRateSlope1: strategy.getStableRateSlope1(),
        stableRateSlope2: strategy.getStableRateSlope2(),
        baseStableRateOffset: (strategy.getBaseStableBorrowRate() > 0)
          ? (strategy.getBaseStableBorrowRate() - strategy.getVariableRateSlope1())
          : 0, // The baseStableRateOffset is not exposed, so needs to be inferred for now
        stableRateExcessOffset: strategy.getStableRateExcessOffset(),
        optimalStableToTotalDebtRatio: strategy.OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO()
      });
  }
}