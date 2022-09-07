// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IPoolFunctionality.sol";
import "../interfaces/IPoolSwapCallback.sol";
import "./SafeTransferHelper.sol";
import "../utils/orionpool/periphery/libraries/OrionMultiPoolLibrary.sol";
import "../utils/orionpool/periphery/OrionPoolV2Router02.sol";
import "./LibUnitConverter.sol";

contract PoolFunctionality is Ownable, IPoolFunctionality {
    using SafeMath for uint;

    address public immutable factory;
    address public immutable WETH;

    address[] public factories;
    mapping(address => bool) public supportedFactories;

    event OrionPoolSwap(
        address sender,
        address st,
        address rt,
        uint st_r,
        uint st_a,
        uint rt_r,
        uint rt_a,
        address f
    );

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
        factories = [_factory];
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function getWETH() external view override returns (address) {
        return WETH;
    }

    function getFactoriesLength() public view returns (uint) {
        return factories.length;
    }

    function updateFactories(address[] calldata _factories) public onlyOwner {
        require(_factories.length > 0, 'PoolFunctionality: FL');
        for (uint i = 0; i < factories.length; i++) {
            supportedFactories[factories[i]] = false;
        }

        factories = _factories;

        for (uint i = 0; i < factories.length; i++) {
            supportedFactories[factories[i]] = true;
        }
    }

    function isFactory(address a) external override view returns (bool) {
        return supportedFactories[a];
    }

    function doSwapThroughOrionPool(
        address     user,
        uint112     amount_spend,
        uint112     amount_receive,
        address[] calldata   path,
        bool        is_exact_spend,
        address     to
    ) external override returns (uint amountOut, uint amountIn) {
        bool isFactory = path.length > 2 && supportedFactories[path[0]];
        address[] memory new_path;
        address curFactory = isFactory ? path[0] : factory;

        if (isFactory) {
            new_path = new address[](path.length - 1);
            for (uint i = 1; i < path.length; ++i) {
                new_path[i - 1] = path[i] == address(0) ? WETH : path[i];
            }
        } else {
            new_path = new address[](path.length);
            for (uint i = 0; i < path.length; ++i) {
                new_path[i] = path[i] == address(0) ? WETH : path[i];
            }
        }

        (uint amount_spend_base_units, uint amount_receive_base_units) =
            (
                LibUnitConverter.decimalToBaseUnit(convertFromWETH(new_path[0]), amount_spend),
                LibUnitConverter.decimalToBaseUnit(path[path.length-1], amount_receive)
            );

        uint[] memory amounts_base_units = _doSwapTokens(
                user,
                amount_spend_base_units,
                amount_receive_base_units,
                isFactory ? path[1] : path[0],
                new_path,
                is_exact_spend,
                to,
                curFactory
            );

        //  Anyway user gave amounts[0] and received amounts[len-1]
        amountOut = LibUnitConverter.baseUnitToDecimal(convertFromWETH(new_path[0]), amounts_base_units[0]);
        amountIn = LibUnitConverter.baseUnitToDecimal(path[path.length-1], amounts_base_units[new_path.length-1]);

    }

    function convertFromWETH(address a) internal view returns (address) {
        return a == WETH ? address(0) : a;
    }

    function pairFor(address curFactory, address tokenA, address tokenB) public view returns (address pair) {
        return OrionMultiPoolLibrary.pairFor(curFactory, tokenA, tokenB);
    }

    function _doSwapTokens(
        address user,
        uint amountIn,
        uint amountOut,
        address asset_spend,
        address[] memory path,
        bool isExactIn, //if true - SwapExactTokensForTokens else SwapTokensForExactTokens
        address to,
        address curFactory
    ) internal returns (uint[] memory amounts) {
        bool isLastWETH = path[path.length - 1] == WETH;
        address toAuto = isLastWETH ?  address(this) : to;

        if (isExactIn) {
            amounts = OrionMultiPoolLibrary.getAmountsOut(curFactory, amountIn, path);
            require(amounts[amounts.length - 1] >= amountOut, 'PoolFunctionality: IOA');
        } else {
            amounts = OrionMultiPoolLibrary.getAmountsIn(curFactory, amountOut, path);
            require(amounts[0] <= amountIn, 'PoolFunctionality: EIA');
        }

        IPoolSwapCallback(msg.sender).safeAutoTransferFrom(asset_spend, user,
            OrionMultiPoolLibrary.pairFor(curFactory, path[0], path[1]), amounts[0]);

        _swap(curFactory, amounts, path, toAuto);

        if (isLastWETH) {
            SafeTransferHelper.safeAutoTransferTo(WETH, address(0), to, amounts[amounts.length - 1]);
        }

        emit OrionPoolSwap(
            tx.origin,
            convertFromWETH(path[0]),
            convertFromWETH(path[path.length-1]),
            amountIn,
            amounts[0],
            amountOut,
            amounts[amounts.length - 1],
            curFactory
        );
    }

    function _swap(address curFactory, uint[] memory amounts, address[] memory path, address _to) internal {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = OrionMultiPoolLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? OrionMultiPoolLibrary.pairFor(curFactory, output, path[i + 2]) : _to;
            IOrionPoolV2Pair(OrionMultiPoolLibrary.pairFor(curFactory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    function addLiquidityFromExchange(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to
    ) external override returns (uint amountA, uint amountB, uint liquidity) {
        amountADesired = LibUnitConverter.decimalToBaseUnit(tokenA, amountADesired);
        amountBDesired = LibUnitConverter.decimalToBaseUnit(tokenB, amountBDesired);

        amountAMin = LibUnitConverter.decimalToBaseUnit(tokenA, amountAMin);
        amountBMin = LibUnitConverter.decimalToBaseUnit(tokenB, amountBMin);

        address tokenAOrWETH = tokenA;
        if (tokenAOrWETH == address(0)) {
            tokenAOrWETH = WETH;
        }

        (amountA, amountB) = _addLiquidity(tokenAOrWETH, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);

        address pair = IOrionPoolV2Factory(factory).getPair(tokenAOrWETH,tokenB);
        IPoolSwapCallback(msg.sender).safeAutoTransferFrom(tokenA, msg.sender, pair, amountA);
        IPoolSwapCallback(msg.sender).safeAutoTransferFrom(tokenB, msg.sender, pair, amountB);

        liquidity = IOrionPoolV2Pair(pair).mint(to);

        amountA = LibUnitConverter.baseUnitToDecimal(tokenA, amountA);
        amountB = LibUnitConverter.baseUnitToDecimal(tokenB, amountB);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IOrionPoolV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IOrionPoolV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = OrionMultiPoolLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = OrionMultiPoolLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'PoolFunctionality: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = OrionMultiPoolLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'PoolFunctionality: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
}