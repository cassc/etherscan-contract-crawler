// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import './core/interfaces/IOrionPoolV2Pair.sol';
import './core/interfaces/IOrionPoolV2Factory.sol';
import "./periphery/interfaces/ICurveRegistry.sol";
import "./periphery/interfaces/ICurvePool.sol";
import "../../interfaces/IPoolFunctionality.sol";
import "../../interfaces/IERC20Simple.sol";

import "../fromOZ/SafeMath.sol";

library OrionMultiPoolLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'OMPL: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'OMPL: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        pair = IOrionPoolV2Factory(factory).getPair(tokenA, tokenB);
    }

    function pairForCurve(address factory, address tokenA, address tokenB) internal view returns (address pool) {
        pool = ICurveRegistry(factory).find_pool_for_coins(tokenA, tokenB, 0);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IOrionPoolV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function get_D(uint256[] memory xp, uint256 amp) internal pure returns(uint256) {
        uint N_COINS = xp.length;
        uint256 S = 0;
        for(uint i; i < N_COINS; ++i)
            S += xp[i];
        if(S == 0)
            return 0;

        uint256 Dprev = 0;
        uint256 D = S;
        uint256 Ann = amp * N_COINS;
        for(uint _i; _i < 255; ++_i) {
            uint256 D_P = D;
            for(uint j; j < N_COINS; ++j) {
                D_P = D_P * D / (xp[j] * N_COINS);  // If division by 0, this will be borked: only withdrawal will work. And that is good
            }
            Dprev = D;
            D = (Ann * S + D_P * N_COINS) * D / ((Ann - 1) * D + (N_COINS + 1) * D_P);
            // Equality with the precision of 1
            if (D > Dprev) {
                if (D - Dprev <= 1)
                    break;
            } else  {
                if (Dprev - D <= 1)
                    break;
            }
        }
        return D;
    }

    function get_y(int128 i, int128 j, uint256 x, uint256[] memory xp_, uint256 amp) pure internal returns(uint256)
    {
        // x in the input is converted to the same price/precision
        uint N_COINS = xp_.length;
        require(i != j, "same coin");
        require(j >= 0, "j below zero");
        require(uint128(j) < N_COINS, "j above N_COINS");

        require(i >= 0, "i below zero");
        require(uint128(i) < N_COINS, "i above N_COINS");

        uint256 D = get_D(xp_, amp);
        uint256 c = D;
        uint256 S_ = 0;
        uint256 Ann = amp * N_COINS;

        uint256 _x = 0;
        for(uint _i; _i < N_COINS; ++_i) {
            if(_i == uint128(i))
                _x = x;
            else if(_i != uint128(j))
                _x = xp_[_i];
            else
                continue;
            S_ += _x;
            c = c * D / (_x * N_COINS);
        }
        c = c * D / (Ann * N_COINS);
        uint256 b = S_ + D / Ann;  // - D
        uint256 y_prev = 0;
        uint256 y = D;
        for(uint _i; _i < 255; ++_i) {
            y_prev = y;
            y = (y*y + c) / (2 * y + b - D);
            // Equality with the precision of 1
            if(y > y_prev) {
                if (y - y_prev <= 1)
                    break;
            } else {
                if(y_prev - y <= 1)
                    break;
            }
        }
        return y;
    }

    function get_xp(address factory, address pool) internal view returns(uint256[] memory xp) {
        xp = new uint256[](MAX_COINS);

        address[MAX_COINS] memory coins = ICurveRegistry(factory).get_coins(pool);
        uint256[MAX_COINS] memory balances = ICurveRegistry(factory).get_balances(pool);

        uint i = 0;
        for (; i < balances.length; ++i) {
            if (balances[i] == 0)
                break;
            xp[i] = baseUnitToCurveDecimal(coins[i], balances[i]);
        }
        assembly { mstore(xp, sub(mload(xp), sub(MAX_COINS, i))) } // remove trail zeros from array
    }

    function getAmountOutCurve(address factory, address from, address to, uint256 amount) view internal returns(uint256) {
        address pool = pairForCurve(factory, from, to);
        (int128 i, int128 j,) = ICurveRegistry(factory).get_coin_indices(pool, from, to);
        uint256[] memory xp = get_xp(factory, pool);

        uint256 y;
        {
            uint256 A = ICurveRegistry(factory).get_A(pool);
            uint256 x = xp[uint(i)] + baseUnitToCurveDecimal(from, amount);
            y = get_y(i, j, x, xp, A);
        }

        (uint256 fee,) = ICurveRegistry(factory).get_fees(pool);
        uint256 dy = xp[uint(j)] - y - 1;
        uint256 dy_fee = dy * fee / FEE_DENOMINATOR;
        dy = curveDecimalToBaseUnit(to, dy - dy_fee);

        return dy;
    }

    function getAmountInCurve(address factory, address from, address to, uint256 amount) view internal returns(uint256) {
        address pool = pairForCurve(factory, from, to);
        (int128 i, int128 j,) = ICurveRegistry(factory).get_coin_indices(pool, from, to);
        uint256[] memory xp = get_xp(factory, pool);

        uint256 x;
        {
            (uint256 fee,) = ICurveRegistry(factory).get_fees(pool);
            uint256 A = ICurveRegistry(factory).get_A(pool);
            uint256 y = xp[uint256(j)] - baseUnitToCurveDecimal(to, (amount + 1)) * FEE_DENOMINATOR / (FEE_DENOMINATOR - fee);
            x = get_y(j, i, y, xp, A);
        }

        uint256 dx = curveDecimalToBaseUnit(from, x - xp[uint256(i)]);
        return dx;
    }

    function getAmountOutUniversal(
        address factory,
        IPoolFunctionality.FactoryType factoryType,
        address from,
        address to,
        uint256 amountIn
    ) view internal returns(uint256 amountOut) {
        if (factoryType == IPoolFunctionality.FactoryType.UNISWAPLIKE) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, from, to);
            amountOut = getAmountOutUv2(amountIn, reserveIn, reserveOut);
        } else if (factoryType == IPoolFunctionality.FactoryType.CURVE) {
            amountOut = getAmountOutCurve(factory, from, to, amountIn);
        } else if (factoryType == IPoolFunctionality.FactoryType.UNSUPPORTED) {
            revert("OMPL: FACTORY_UNSUPPORTED");
        }
    }

    function getAmountInUniversal(
        address factory,
        IPoolFunctionality.FactoryType factoryType,
        address from,
        address to,
        uint256 amountOut
    ) view internal returns(uint256 amountIn) {
        if (factoryType == IPoolFunctionality.FactoryType.UNISWAPLIKE) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, from, to);
            amountIn = getAmountInUv2(amountOut, reserveIn, reserveOut);
        } else if (factoryType == IPoolFunctionality.FactoryType.CURVE) {
            amountIn = getAmountInCurve(factory, from, to, amountOut);
        } else if (factoryType == IPoolFunctionality.FactoryType.UNSUPPORTED) {
            revert("OMPL: FACTORY_UNSUPPORTED");
        }
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        IPoolFunctionality.FactoryType factoryType,
        uint amountIn,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'OMPL: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;

        for (uint i = 1; i < path.length; ++i) {
            amounts[i] = getAmountOutUniversal(factory, factoryType, path[i - 1], path[i], amounts[i - 1]);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        IPoolFunctionality.FactoryType factoryType,
        uint amountOut,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'OMPL: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; --i) {
            amounts[i - 1] = getAmountInUniversal(factory, factoryType, path[i - 1], path[i], amounts[i]);
        }
    }

    /**
        @notice convert asset amount from decimals (10^18) to its base unit
    */
    function curveDecimalToBaseUnit(address assetAddress, uint amount) internal view returns(uint256 baseValue){
        uint256 result;

        if(assetAddress == address(0)){
            result = amount; // 18 decimals
        } else {
            uint decimals = IERC20Simple(assetAddress).decimals();

            result = amount.mul(10**decimals).div(10**18);
        }

        baseValue = result;
    }

    /**
        @notice convert asset amount from its base unit to 18 decimals (10^18)
    */
    function baseUnitToCurveDecimal(address assetAddress, uint amount) internal view returns(uint256 decimalValue){
        uint256 result;

        if(assetAddress == address(0)){
            result = amount;
        } else {
            uint decimals = IERC20Simple(assetAddress).decimals();

            result = amount.mul(10**18).div(10**decimals);
        }
        decimalValue = result;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOutUv2(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'OMPL: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'OMPL: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountInUv2(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'OMPL: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'OMPL: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quoteUv2(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'OMPL: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'OMPL: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

}