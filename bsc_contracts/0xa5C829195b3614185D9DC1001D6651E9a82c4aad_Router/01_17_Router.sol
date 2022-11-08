// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IPoolFactory.sol";
import "./interfaces/ITokenFactory.sol";
import "./interfaces/ILogic.sol";
import "./interfaces/IPool.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@derivable/oracle/contracts/@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@derivable/oracle/contracts/Math.sol";
import "@derivable/oracle/contracts/OracleLibrary.sol";

contract Router {
    IPoolFactory public immutable POOL_FACTORY;
    ITokenFactory public immutable TOKEN_FACTORY;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "DDLV1Router: EXPIRED");
        _;
    }

    constructor(
        address poolFactory,
        address tokenFactory
    ) {
        POOL_FACTORY = IPoolFactory(poolFactory);
        TOKEN_FACTORY = ITokenFactory(tokenFactory);
    }

    function creatPool(address logic) public {
        POOL_FACTORY.createPool(logic);
        for (uint256 index = 0; index < ILogic(logic).N_TOKENS(); index++) {
            TOKEN_FACTORY.createDToken(logic, index);
        }
    }

    struct Step {
        address tokenIn;
        address tokenOut;
        uint amountIn;
        uint amountOutMin;
    }

    function multiSwap(
        address pool,
        Step[] calldata steps,
        address to,
        uint256 deadline,
        uint fee10000
    ) public ensure(deadline) returns (uint[] memory amountOuts, uint gasLeft) {
        amountOuts = new uint[](steps.length);
        CTokens memory cTokens;
        if (fee10000 > 0) {
            cTokens.pair = IPool(pool).COLLATERAL_TOKEN();
            cTokens.token0 = IUniswapV2Pair(cTokens.pair).token0();
            cTokens.token1 = IUniswapV2Pair(cTokens.pair).token1();
        }
        for (uint i = 0; i < steps.length; ++i) {
            Step memory step = steps[i];
            if (step.tokenOut == address(0)) {
                uint start = step.amountIn;
                uint end = step.amountOutMin;
                ILogic(IPool(pool).LOGIC()).deleverage(uint224(start), uint224(end));
                continue;
            }
            if (fee10000 > 0 && (step.tokenIn == cTokens.token0 || step.tokenIn == cTokens.token1)) {
                _swapToLP(
                    cTokens,
                    step,
                    fee10000,
                    pool
                );
                step.tokenIn = cTokens.pair; // switch the tokenIn to pair
            } else {
                TransferHelper.safeTransferFrom(step.tokenIn, msg.sender, pool, step.amountIn);
            }
            (amountOuts[i], ) = IPool(pool).swap(step.tokenIn, step.tokenOut, to);
            require(amountOuts[i] >= step.amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
        }
        gasLeft = gasleft();
    }

    struct CTokens {
        address pair;
        address token0;
        address token1;
    }

    function _swapToLP(
        CTokens memory cTokens,
        Step memory step,
        uint fee10000,
        address to
    ) internal returns (uint amountOut) {
        address otherToken = step.tokenIn == cTokens.token0 ? cTokens.token1 : cTokens.token0;
        uint amountOtherMax = Math.min(
            IERC20(otherToken).balanceOf(msg.sender),
            IERC20(otherToken).allowance(msg.sender, address(this))
        );
        return _swapToLP(
            cTokens.pair,
            step.tokenIn,
            otherToken,
            step.amountIn,
            amountOtherMax,
            fee10000,
            to
        );
    }

    // https://blog.alphaventuredao.io/onesideduniswap/
    function _getSwapAmt(uint res, uint amt, uint fee) internal pure returns (uint) {
        uint q1997 = (20000-fee) * (20000-fee);
        uint u4k997 = 40000 * (10000-fee);
        return(Math.sqrt(res*(amt*u4k997 + res*q1997)) - res*19970) / 19940;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function _getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint fee) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn * (10000-fee);
        uint numerator = amountInWithFee * (reserveOut);
        uint denominator = reserveIn*10000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function _swapToLP(
        address pair,
        address mainToken,
        address otherToken,
        uint amountMainDesired,
        uint amountOtherMax,
        uint fee10000,
        address to
    ) internal returns (uint amountOut) {
        (uint rMain, uint rOther) = _getReserves(pair, mainToken, otherToken);
        amountMainDesired /= 2;
        uint amountOtherDesired = amountMainDesired * rOther / rMain;
        if (amountOtherDesired > amountOtherMax) {
            if (amountOtherMax > 0) {
                uint amountMainMax = amountOtherMax * rMain / rOther;
                TransferHelper.safeTransferFrom(mainToken, msg.sender, pair, amountMainMax);
                TransferHelper.safeTransferFrom(otherToken, msg.sender, pair, amountOtherMax);
                amountOut += IUniswapV2Pair(pair).mint(to);
                amountMainDesired -= amountMainMax;
                rMain += amountMainMax;
                rOther += amountOtherMax;
            }
            uint mainIn = _getSwapAmt(rMain, amountMainDesired*2, fee10000);
            amountOtherDesired = _getAmountOut(mainIn, rMain, rOther, fee10000);
            TransferHelper.safeTransferFrom(mainToken, msg.sender, pair, mainIn);
            // swap A->B
            if (mainToken < otherToken) {
                IUniswapV2Pair(pair).swap(0, amountOtherDesired, address(this), bytes(""));
            } else {
                IUniswapV2Pair(pair).swap(amountOtherDesired, 0, address(this), bytes(""));
            }
            TransferHelper.safeTransfer(otherToken, pair, amountOtherDesired);
            rMain += mainIn;
            rOther -= amountOtherDesired;
            amountMainDesired = amountOtherDesired * rMain / rOther;
        } else {
            TransferHelper.safeTransferFrom(otherToken, msg.sender, pair, amountOtherDesired);
        }
        TransferHelper.safeTransferFrom(mainToken, msg.sender, pair, amountMainDesired);
        amountOut += IUniswapV2Pair(pair).mint(to);
    }

    function swapToLP(
        address pair,
        address mainToken,
        address otherToken,
        uint amountMainDesired,
        uint amountOtherMax,
        uint fee10000,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint amountOut, uint gasLeft) {
        return (
            _swapToLP(
                pair,
                mainToken,
                otherToken,
                amountMainDesired,
                amountOtherMax,
                fee10000,
                to
            ),
            gasleft()
        );
    }

    function _getReserves(address pair, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA < tokenB ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getStates(address logic) external view returns (
        uint Rc,
        uint32 priceScaleTimestamp,
        uint224 priceScaleLong,
        uint224 priceScaleShort,
        OracleStore memory oracleStore,
        OraclePrice memory twap,
        OraclePrice memory spot
    ) {
        (
            Rc,
            oracleStore.basePriceCumulative,
            oracleStore.blockTimestamp,
            oracleStore.baseTWAP._x,
            priceScaleTimestamp,
            priceScaleLong,
            priceScaleShort
        ) = ILogic(logic).getStates();
        (twap, spot, ) = OracleLibrary.peekPrice(oracleStore, ILogic(logic).COLLATERAL_TOKEN(), ILogic(logic).BASE_TOKEN_0());
    }
}