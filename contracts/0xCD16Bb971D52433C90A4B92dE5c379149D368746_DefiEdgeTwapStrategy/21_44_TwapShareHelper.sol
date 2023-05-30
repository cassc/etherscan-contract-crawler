//SPDX-License-Identifier: BSL
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";

import "./TwapOracleLibrary.sol";

library TwapShareHelper {
    using SafeMath for uint256;

    uint256 public constant DIVISOR = 100e18;

    /**
     * @dev Calculates the shares to be given for specific position
     * @param _registry Chainlink registry interface
     * @param _pool The token0
     * @param _amount0 Amount of token0
     * @param _amount1 Amount of token1
     * @param _totalAmount0 Total amount of token0
     * @param _totalAmount1 Total amount of token1
     * @param _totalShares Total Number of shares
     */
    function calculateShares(
        FeedRegistryInterface _registry,
        IUniswapV3Pool _pool,
        ITwapStrategyManager _manager,
        bool[2] memory _useTwap,
        uint256 _amount0,
        uint256 _amount1,
        uint256 _totalAmount0,
        uint256 _totalAmount1,
        uint256 _totalShares
    ) public view returns (uint256 share) {
        require(_amount0 > 0 && _amount1 > 0, "INSUFFICIENT_AMOUNT");

        address _token0 = _pool.token0();
        address _token1 = _pool.token1();

        _amount0 = TwapOracleLibrary.normalise(_token0, _amount0);
        _amount1 = TwapOracleLibrary.normalise(_token1, _amount1);
        _totalAmount0 = TwapOracleLibrary.normalise(_token0, _totalAmount0);
        _totalAmount1 = TwapOracleLibrary.normalise(_token1, _totalAmount1);

        if (_totalShares > 0) {
            if (_amount0 < _amount1) {
                share = FullMath.mulDiv(_amount1, _totalShares, _totalAmount1);
            } else {
                share = FullMath.mulDiv(_amount0, _totalShares, _totalAmount0);
            }
        } else {
            // price in USD
            (uint256 token0Price, uint256 token1Price) = _getPrice(_pool, _registry, _useTwap, _manager);

            share = ((token0Price.mul(_amount0)).add(token1Price.mul(_amount1))).div(DIVISOR);
        }
    }

    /**
     * @notice Calculates the fee shares from accumulated fees
     * @param _factory Strategy factory address
     * @param _manager Strategy manager contract address
     * @param _accManagementFee Accumulated management fees in terms of shares, decimal 18
     */
    function calculateFeeShares(
        ITwapStrategyFactory _factory,
        ITwapStrategyManager _manager,
        uint256 _accManagementFee
    )
        public
        view
        returns (
            address managerFeeTo,
            address protocolFeeTo,
            uint256 managerShare,
            uint256 protocolShare
        )
    {
        uint256 protocolFeeRate = _factory.protocolFeeRate();

        // calculate the fees for protocol and manager from management fees
        if (_accManagementFee > 0) {
            protocolShare = FullMath.mulDiv(_accManagementFee, protocolFeeRate, 1e8);
            managerShare = _accManagementFee.sub(protocolShare);
        }

        // moved here for saving bytecode
        managerFeeTo = _manager.feeTo();
        protocolFeeTo = _factory.feeTo();
    }

    /**
     * @notice Calculates the fee shares from accumulated fees
     * @param _factory Strategy factory address
     * @param _manager Strategy manager contract address
     * @param _fee0 Accumulated token0 fee amount
     * @param _fee1 Accumulated token1  fee amount
     */
    function calculateFeeTokenShares(
        ITwapStrategyFactory _factory,
        ITwapStrategyManager _manager,
        uint256 _fee0,
        uint256 _fee1
    )
        public
        view
        returns (
            address managerFeeTo,
            address protocolFeeTo,
            uint256 managerToken0Amount,
            uint256 managerToken1Amount,
            uint256 protocolToken0Amount,
            uint256 protocolToken1Amount
        )
    {
        // protocol fees
        uint256 protocolFeeRate = _factory.protocolFeeRate();

        // performance fee to manager
        uint256 performanceFeeRate = _manager.performanceFeeRate();

        // protocol performance fee
        uint256 protocolPerformanceFeeRate = _factory.protocolPerformanceFeeRate();

        // calculate the fees for protocol and manager from performance fees
        uint256 performanceToken0Amount = FullMath.mulDiv(_fee0, performanceFeeRate, 1e8);
        uint256 performanceToken1Amount = FullMath.mulDiv(_fee1, performanceFeeRate, 1e8);

        if (performanceToken0Amount > 0) {
            protocolToken0Amount = FullMath.mulDiv(performanceToken0Amount, protocolFeeRate, 1e8);
            managerToken0Amount = performanceToken0Amount.sub(protocolToken0Amount);
        }

        if (performanceToken1Amount > 0) {
            protocolToken1Amount = FullMath.mulDiv(performanceToken1Amount, protocolFeeRate, 1e8);
            managerToken1Amount = performanceToken1Amount.sub(protocolToken1Amount);
        }

        protocolToken0Amount = protocolToken0Amount.add(FullMath.mulDiv(_fee0, protocolPerformanceFeeRate, 1e8));
        protocolToken1Amount = protocolToken1Amount.add(FullMath.mulDiv(_fee1, protocolPerformanceFeeRate, 1e8));

        // moved here for saving bytecode
        managerFeeTo = _manager.feeTo();
        protocolFeeTo = _factory.feeTo();
    }

    function getOptimalAmounts(
        uint256 _amount0,
        uint256 _amount1,
        uint256 _amount0Min,
        uint256 _amount1Min,
        uint256 _totalAmount0,
        uint256 _totalAmount1
    ) public pure returns (uint256 amount0, uint256 amount1) {
        require(_amount0 > 0 && _amount1 > 0, "INSUFFICIENT_AMOUNT");

        if (_totalAmount0 == 0 && _totalAmount1 == 0) {
            (amount0, amount1) = (_amount0, _amount1);
        } else {
            if (_totalAmount0 == 0) {
                require(_amount0Min == 0, "INSUFFICIENT_AMOUNT_0");
                (amount0, amount1) = (0, _amount1);
                return (amount0, amount1);
            }
            if (_totalAmount1 == 0) {
                require(_amount1Min == 0, "INSUFFICIENT_AMOUNT_1");
                (amount0, amount1) = (_amount0, 0);
                return (amount0, amount1);
            }
            uint256 amount1Optimal = _amount0.mul(_totalAmount1).div(_totalAmount0);
            if (amount1Optimal <= _amount1) {
                require(amount1Optimal >= _amount1Min, "INSUFFICIENT_AMOUNT_1");
                (amount0, amount1) = (_amount0, amount1Optimal);
            } else {
                uint256 amount0Optimal = _amount1.mul(_totalAmount0).div(_totalAmount1);
                assert(amount0Optimal <= _amount0);
                require(amount0Optimal >= _amount0Min, "INSUFFICIENT_AMOUNT_0");
                (amount0, amount1) = (amount0Optimal, _amount1);
            }
        }
    }

    // to resolve stack too deep error
    function _getPrice(
        IUniswapV3Pool _pool,
        FeedRegistryInterface _registry,
        bool[2] memory _useTwap,
        ITwapStrategyManager _manager
    ) internal view returns (uint256 token0Price, uint256 token1Price) {
        // price in USD
        token0Price = TwapOracleLibrary.getPriceInUSD(_manager.factory(), _pool, _registry, _pool.token0(), _useTwap, _manager);

        token1Price = TwapOracleLibrary.getPriceInUSD(_manager.factory(), _pool, _registry, _pool.token1(), _useTwap, _manager);
    }
}