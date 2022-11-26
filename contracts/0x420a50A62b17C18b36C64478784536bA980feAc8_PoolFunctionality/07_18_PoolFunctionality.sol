// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../interfaces/IERC20.sol";
import "../utils/fromOZ/SafeMath.sol";
import "../utils/fromOZ/SafeERC20.sol";
import "../utils/fromOZ/Ownable.sol";

import "../interfaces/IPoolFunctionality.sol";
import "../interfaces/IPoolSwapCallback.sol";
import "./SafeTransferHelper.sol";
import "../utils/orionpool/OrionMultiPoolLibrary.sol";
import "../utils/orionpool/periphery/interfaces/ICurvePool.sol";
import "./LibUnitConverter.sol";

contract PoolFunctionality is Ownable, IPoolFunctionality {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable factory;
    address public immutable WETH;

    address[] public factories;

    mapping(address => FactoryType) public supportedFactories;

    event OrionPoolSwap(
        address sender,
        address st,
        address rt,
        uint256 st_r,
        uint256 st_a,
        uint256 rt_r,
        uint256 rt_a,
        address f
    );

    constructor(address _factory, FactoryType _type, address _WETH) {
        factory = _factory;
        WETH = _WETH;
        factories = [_factory];
        supportedFactories[_factory] = _type;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function getWETH() external view override returns (address) {
        return WETH;
    }

    function getFactoriesLength() public view returns (uint256) {
        return factories.length;
    }

    function updateFactories(
        address[] calldata _factories,
        FactoryType[] calldata _types
    ) public onlyOwner {
        require(_factories.length > 0, "PoolFunctionality: FL");
        for (uint256 i = 0; i < factories.length; ++i) {
            supportedFactories[factories[i]] = FactoryType.UNSUPPORTED;
        }

        factories = _factories;

        for (uint256 i = 0; i < factories.length; i++) {
            supportedFactories[factories[i]] = _types[i];
        }
    }

    function isFactory(address a) external view override returns (bool) {
        return supportedFactories[a] != FactoryType.UNSUPPORTED;
    }

    function doSwapThroughOrionPool(
        address user,
        address to,
        IPoolFunctionality.SwapData calldata swapData
    ) external override returns (uint256 amountOut, uint256 amountIn) {
        bool withFactory = swapData.path.length > 2 &&
            (supportedFactories[swapData.path[0]] != FactoryType.UNSUPPORTED);
        address curFactory = withFactory ? swapData.path[0] : factory;
        address[] memory new_path;

        uint256 tokenIndex = withFactory ? 1 : 0;
        new_path = new address[](swapData.path.length - tokenIndex);

        for ((uint256 i, uint256 j) = (tokenIndex, 0); i < swapData.path.length; (++i, ++j)) {
            new_path[j] = swapData.path[i] == address(0) ? WETH : swapData.path[i];
        }

        (uint256 amount_spend_base_units, uint256 amount_receive_base_units) = (
            LibUnitConverter.decimalToBaseUnit(
                swapData.path[tokenIndex],
                swapData.amount_spend
            ),
            LibUnitConverter.decimalToBaseUnit(
                swapData.path[swapData.path.length - 1],
                swapData.amount_receive
            )
        );
        {
        (uint256 userAmountIn, uint256 userAmountOut) = _doSwapTokens(InternalSwapData(
            user,
            amount_spend_base_units,
            amount_receive_base_units,
            withFactory ? swapData.path[1] : swapData.path[0],
            new_path,
            swapData.is_exact_spend,
            to,
            curFactory,
            supportedFactories[curFactory],
            swapData.supportingFee
        ));

        //  Anyway user gave amounts[0] and received amounts[len-1]
        amountOut = LibUnitConverter.baseUnitToDecimal(
            swapData.path[tokenIndex],
            userAmountIn
        );
        amountIn = LibUnitConverter.baseUnitToDecimal(
            swapData.path[swapData.path.length - 1],
            userAmountOut
        );
        }
    }

    function convertFromWETH(address a) internal view returns (address) {
        return a == WETH ? address(0) : a;
    }

    function pairFor(
        address curFactory,
        address tokenA,
        address tokenB
    ) public view returns (address pair) {
        return OrionMultiPoolLibrary.pairFor(curFactory, tokenA, tokenB);
    }

    function _doSwapTokens(InternalSwapData memory swapData) internal returns (uint256 amountIn, uint256 amountOut) {
        bool isLastWETH = swapData.path[swapData.path.length - 1] == WETH;
        address toAuto = isLastWETH || swapData.curFactoryType == FactoryType.CURVE ? address(this) : swapData.to;
        uint256[] memory amounts;
        if (!swapData.supportingFee) {
            if (swapData.isExactIn) {
                amounts = OrionMultiPoolLibrary.getAmountsOut(
                    swapData.curFactory,
                    swapData.curFactoryType,
                    swapData.amountIn,
                    swapData.path
                );
                require(amounts[amounts.length - 1] >= swapData.amountOut, "PoolFunctionality: IOA");
            } else {
                amounts = OrionMultiPoolLibrary.getAmountsIn(
                    swapData.curFactory,
                    swapData.curFactoryType,
                    swapData.amountOut,
                    swapData.path
                );
                require(amounts[0] <= swapData.amountIn, "PoolFunctionality: EIA");
            }
        } else {
            amounts = new uint256[](1);
            amounts[0] = swapData.amountIn;
        }
        amountIn = amounts[0];

        {
            uint256 curBalance;
            address initialTransferSource = swapData.curFactoryType == FactoryType.CURVE ? address(this)
                : OrionMultiPoolLibrary.pairFor(swapData.curFactory, swapData.path[0], swapData.path[1]);

            if (swapData.supportingFee) curBalance = IERC20(swapData.path[0]).balanceOf(initialTransferSource);

            IPoolSwapCallback(msg.sender).safeAutoTransferFrom(
                swapData.asset_spend,
                swapData.user,
                initialTransferSource,
                amountIn
            );
            if (swapData.supportingFee) amounts[0] = IERC20(swapData.path[0]).balanceOf(initialTransferSource) - curBalance;
        }

        {
            uint256 curBalance = IERC20(swapData.path[swapData.path.length - 1]).balanceOf(toAuto);
            if (swapData.curFactoryType == FactoryType.CURVE) {
                _swapCurve(swapData.curFactory, amounts, swapData.path, swapData.supportingFee);
            } else if (swapData.curFactoryType == FactoryType.UNISWAPLIKE) {
                _swap(swapData.curFactory, amounts, swapData.path, toAuto, swapData.supportingFee);
            }
            amountOut = IERC20(swapData.path[swapData.path.length - 1]).balanceOf(toAuto) - curBalance;
        }

        require(
            swapData.amountIn == 0 || swapData.amountOut == 0 ||
            amountIn * 1e18 / swapData.amountIn <= amountOut * 1e18 / swapData.amountOut,
            "PoolFunctionality: OOS"
        );

        if (isLastWETH) {
            SafeTransferHelper.safeAutoTransferTo(
                WETH,
                address(0),
                swapData.to,
                amountOut
            );
        } else if (swapData.curFactoryType == FactoryType.CURVE) {
            IERC20(swapData.path[swapData.path.length - 1]).safeTransfer(swapData.to, amountOut);
        }

        emit OrionPoolSwap(
            tx.origin,
            convertFromWETH(swapData.path[0]),
            convertFromWETH(swapData.path[swapData.path.length - 1]),
            swapData.amountIn,
            amountIn,
            swapData.amountOut,
            amountOut,
            swapData.curFactory
        );
    }

    function _swap(
        address curFactory,
        uint256[] memory amounts,
        address[] memory path,
        address _to,
        bool supportingFee
    ) internal {
        for (uint256 i; i < path.length - 1; ++i) {
            (address input, address output) = (path[i], path[i + 1]);
            IOrionPoolV2Pair pair = IOrionPoolV2Pair(OrionMultiPoolLibrary.pairFor(curFactory, input, output));
            (address token0, ) = OrionMultiPoolLibrary.sortTokens(input, output);
            uint256 amountOut;

            if (supportingFee) {
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                uint256 amountIn = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOut = OrionMultiPoolLibrary.getAmountOutUv2(amountIn, reserveInput, reserveOutput);
            } else {
                amountOut = amounts[i + 1];
            }

            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? OrionMultiPoolLibrary.pairFor(curFactory, output, path[i + 2]) : _to;

            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function _swapCurve(
        address curFactory,
        uint256[] memory amounts,
        address[] memory path,
        bool supportingFee
    ) internal {
        for (uint256 i; i < path.length - 1; ++i) {
            (address input, address output) = (path[i], path[i + 1]);
            address pool = OrionMultiPoolLibrary.pairForCurve(curFactory, input, output);
            (int128 inputInd, int128 outputInd,) = ICurveRegistry(curFactory).get_coin_indices(pool, input, output);

            uint256 curBalance;
            uint amountsIndex = supportingFee ? 0 : i;
            if (supportingFee) curBalance = IERC20(path[i + 1]).balanceOf(address(this));
            
            if (IERC20(input).allowance(address(this), pool) < amounts[amountsIndex]) {
                IERC20(input).safeIncreaseAllowance(pool, type(uint256).max);
            }
            ICurvePool(pool).exchange(inputInd, outputInd, amounts[amountsIndex], 0);
            
            if (supportingFee) amounts[0] = IERC20(path[i + 1]).balanceOf(address(this)) - curBalance;
        }
    }

    function addLiquidityFromExchange(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    )
        external
        override
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        amountADesired = LibUnitConverter.decimalToBaseUnit(
            tokenA,
            amountADesired
        );
        amountBDesired = LibUnitConverter.decimalToBaseUnit(
            tokenB,
            amountBDesired
        );
        amountAMin = LibUnitConverter.decimalToBaseUnit(tokenA, amountAMin);
        amountBMin = LibUnitConverter.decimalToBaseUnit(tokenB, amountBMin);

        address tokenAOrWETH = tokenA;
        if (tokenAOrWETH == address(0)) {
            tokenAOrWETH = WETH;
        }

        (amountA, amountB) = _addLiquidity(
            tokenAOrWETH,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );

        address pair = IOrionPoolV2Factory(factory).getPair(
            tokenAOrWETH,
            tokenB
        );
        IPoolSwapCallback(msg.sender).safeAutoTransferFrom(
            tokenA,
            msg.sender,
            pair,
            amountA
        );
        IPoolSwapCallback(msg.sender).safeAutoTransferFrom(
            tokenB,
            msg.sender,
            pair,
            amountB
        );

        liquidity = IOrionPoolV2Pair(pair).mint(to);

        amountA = LibUnitConverter.baseUnitToDecimal(tokenA, amountA);
        amountB = LibUnitConverter.baseUnitToDecimal(tokenB, amountB);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (
            IOrionPoolV2Factory(factory).getPair(tokenA, tokenB) == address(0)
        ) {
            IOrionPoolV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = OrionMultiPoolLibrary.getReserves(
            factory,
            tokenA,
            tokenB
        );
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = OrionMultiPoolLibrary.quoteUv2(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "PoolFunctionality: INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = OrionMultiPoolLibrary.quoteUv2(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "PoolFunctionality: INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
}