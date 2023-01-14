// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

import './interfaces/INomiswapRouter02.sol';
import './libraries/BalancerLibrary.sol';
import './libraries/NomiswapLibrary.sol';
import './interfaces/IWETH.sol';

interface INomiswapStablePairExtended is INomiswapStablePair {
    function token0PrecisionMultiplier() external view returns (uint128);
    function token1PrecisionMultiplier() external view returns (uint128);
}

contract NomiswapRouter04 {

    address public immutable factory;
    address public immutable stableSwapFactory;
    address public immutable WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'NomiswapRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _stableSwapFactory, address _WETH) {
        factory = _factory;
        stableSwapFactory = _stableSwapFactory;
        WETH = _WETH;
    }

    receive() external payable {
        require(msg.sender == WETH, 'NomiswapRouter: ONLY_WETH'); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address _factory,
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) private returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (INomiswapFactory(_factory).getPair(tokenA, tokenB) == address(0)) {
            INomiswapFactory(_factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = NomiswapLibrary.getReserves(_factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = NomiswapLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'NomiswapRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = NomiswapLibrary.quote(amountBDesired, reserveB, reserveA);
                require(amountAOptimal <= amountADesired, 'NomiswapRouter: TOO_MUCH_A_AMOUNT');
                require(amountAOptimal >= amountAMin, 'NomiswapRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function balanceLiquidity(
        address _factory,
        address token0,
        address token1,
        uint amount0Desired,
        uint amount1Desired
    ) public view returns (uint[4] memory) {
        (uint reserve0, uint reserve1) = NomiswapLibrary.getReserves(_factory, token0, token1);
        if (reserve0 == 0 && reserve1 == 0) {
            uint[4] memory _result;
            return _result;
        } else {
            uint fee = NomiswapLibrary.getSwapFee(_factory, token0, token1);
            uint[4] memory r = [reserve0, reserve1, amount0Desired, amount1Desired];
            if (_factory == factory) {
                return BalancerLibrary.balanceLiquidityCP(r, 1000 - fee, 1000);
            } else if (_factory == stableSwapFactory) {
                address pair = _getPair(token0, token1);
                uint128 token0PrecisionMultiplier = INomiswapStablePairExtended(pair).token0PrecisionMultiplier();
                uint128 token1PrecisionMultiplier = INomiswapStablePairExtended(pair).token1PrecisionMultiplier();
                r[0] = r[0] * token0PrecisionMultiplier;
                r[1] = r[1] * token1PrecisionMultiplier;
                r[2] = r[2] * token0PrecisionMultiplier;
                r[3] = r[3] * token1PrecisionMultiplier;
                uint a = INomiswapStablePair(pair).getA();
                uint[4] memory result = BalancerLibrary.balanceLiquiditySS(r, 4294967295 - fee, 4294967295, a, 100);
                result[0] = divRoundUp(result[0], token0PrecisionMultiplier);
                result[1] = divRoundUp(result[1], token1PrecisionMultiplier);
                result[2] = result[2] / token0PrecisionMultiplier;
                result[3] = result[3] / token1PrecisionMultiplier;
                return result;
            } else {
                revert('NomiswapRouter: UNEXPECTED_FACTORY_TYPE');
            }
        }
    }

    function divRoundUp(uint numerator, uint denumerator) private pure returns (uint) {
        return (numerator + denumerator - 1) / denumerator;
    }

    function _addLiquidityImbalanced(
        address _factory,
        address token0,
        address token1,
        uint amount0Desired,
        uint amount1Desired,
        uint amount0Min,
        uint amount1Min
    ) private returns (uint[4] memory) {
        // create the pair if it doesn't exist yet
        if (INomiswapFactory(_factory).getPair(token0, token1) == address(0)) {
            INomiswapFactory(_factory).createPair(token0, token1);
        }
        uint[4] memory result = balanceLiquidity(_factory, token0, token1, amount0Desired, amount1Desired);
        require(amount0Desired - result[0] + result[2] >= amount0Min, 'NomiswapRouter: INSUFFICIENT_0_AMOUNT');
        require(amount1Desired - result[1] + result[3] >= amount1Min, 'NomiswapRouter: INSUFFICIENT_1_AMOUNT');
        return result;
    }

    function _getFactory(address tokenA, address tokenB) private view returns (address _factory) {
        _factory = stableSwapFactory;
        if (INomiswapFactory(_factory).getPair(tokenA, tokenB) == address(0)) {
            _factory = factory;
        }
    }

    function _getPairAndFactory(address tokenA, address tokenB) private view returns (address, address) {
        address _factory = stableSwapFactory;
        address pair = INomiswapFactory(_factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            _factory = factory;
            pair = NomiswapLibrary.pairFor(_factory, tokenA, tokenB);
        }
        return (pair, _factory);
    }

    function _getPair(address tokenA, address tokenB) private view returns (address pair) {
        pair = INomiswapFactory(stableSwapFactory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = NomiswapLibrary.pairFor(factory, tokenA, tokenB);
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        address _factory = _getFactory(tokenA, tokenB);
        (amountA, amountB) = _addLiquidity(_factory, tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = NomiswapLibrary.pairFor(_factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = INomiswapPair(pair).mint(to);
    }

    function addLiquidityImbalanced(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (address token0, ) = NomiswapLibrary.sortTokens(tokenA, tokenB);
        if (tokenA == token0) {
            liquidity = addLiquidityImbalancedSorted(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline);
        } else {
            liquidity = addLiquidityImbalancedSorted(tokenB, tokenA, amountBDesired, amountADesired, amountBMin, amountAMin, to, deadline);
        }
        amountA = amountADesired;
        amountB = amountBDesired;
    }

    function addLiquidityImbalancedSorted(
        address token0,
        address token1,
        uint amount0Desired,
        uint amount1Desired,
        uint amount0Min,
        uint amount1Min,
        address to,
        uint deadline
    ) private ensure(deadline) returns (uint liquidity) {
        address _factory = _getFactory(token0, token1);
        uint[4] memory balanceResult = _addLiquidityImbalanced(_factory, token0, token1, amount0Desired, amount1Desired, amount0Min, amount1Min);
        address pair = NomiswapLibrary.pairFor(_factory, token0, token1);
        if (balanceResult[0] > 0) {
            if (token0 != WETH) {
                TransferHelper.safeTransferFrom(token0, msg.sender, pair, balanceResult[0]);
            } else {
                TransferHelper.safeTransfer(WETH, pair, balanceResult[0]);
            }          
        }
        if (balanceResult[1] > 0) {
            if (token1 != WETH) {
                TransferHelper.safeTransferFrom(token1, msg.sender, pair, balanceResult[1]);
            } else {
                TransferHelper.safeTransfer(WETH, pair, balanceResult[1]);
            }          
        }
        if (balanceResult[2] > 0 || balanceResult[3] > 0) {
            INomiswapPair(pair).swap(balanceResult[2], balanceResult[3], address(this), new bytes(0));
        }
        if (balanceResult[2] > 0) {
          TransferHelper.safeTransfer(token0, pair, balanceResult[2]);
        }
        if (balanceResult[3] > 0) {
          TransferHelper.safeTransfer(token1, pair, balanceResult[3]);
        }
        if (token0 != WETH) {
            TransferHelper.safeTransferFrom(token0, msg.sender, pair, amount0Desired - balanceResult[0]);
        } else {
            TransferHelper.safeTransfer(WETH, pair, amount0Desired - balanceResult[0]);
        }
        if (token1 != WETH) {
            TransferHelper.safeTransferFrom(token1, msg.sender, pair, amount1Desired - balanceResult[1]);
        } else {
            TransferHelper.safeTransfer(WETH, pair, amount1Desired - balanceResult[1]);
        }

        liquidity = INomiswapPair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            factory,
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = _getPair(token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        require(IWETH(WETH).transfer(pair, amountETH), 'NomiswapRouter: FAILED_TO_TRANSFER');
        liquidity = INomiswapPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    function addLiquidityETHImbalanced(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        IWETH(WETH).deposit{value: msg.value}();
        require(IWETH(WETH).transfer(address(this), msg.value), 'NomiswapRouter: FAILED_TO_TRANSFER');
        (address token0, ) = NomiswapLibrary.sortTokens(token, WETH);
        if (token == token0) {
            liquidity = addLiquidityImbalancedSorted(token, WETH, amountTokenDesired, msg.value, amountTokenMin, amountETHMin, to, deadline);
        } else {
            liquidity = addLiquidityImbalancedSorted(WETH, token, msg.value, amountTokenDesired, amountETHMin, amountTokenMin, to, deadline);
        }
        amountToken = amountTokenDesired;
        amountETH = msg.value;
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = _getPair(tokenA, tokenB);
        require(INomiswapPair(pair).transferFrom(msg.sender, pair, liquidity), 'NomiswapRouter: FAILED_TO_TRANSFER'); // send liquidity to pair
        (uint amount0, uint amount1) = INomiswapPair(pair).burn(to);
        (address token0,) = NomiswapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'NomiswapRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'NomiswapRouter: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB) {
        address pair = _getPair(tokenA, tokenB);
        uint value = approveMax ? type(uint256).max : liquidity;
        INomiswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH) {
        address pair = _getPair(token, WETH);
        uint value = approveMax ? type(uint256).max : liquidity;
        INomiswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH) {
        address pair = _getPair(token, WETH);
        uint value = approveMax ? type(uint256).max : liquidity;
        INomiswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) private {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = NomiswapLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? _getPair(output, path[i + 2]) : _to;
            address pair = _getPair(input, output);
            INomiswapPair(pair).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        amounts = NomiswapLibrary.getAmountsOut(factory, stableSwapFactory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'NomiswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, _getPair(path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        amounts = NomiswapLibrary.getAmountsIn(factory, stableSwapFactory, amountOut, path);
        require(amounts[0] <= amountInMax, 'NomiswapRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, _getPair(path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'NomiswapRouter: INVALID_PATH');
        amounts = NomiswapLibrary.getAmountsOut(factory, stableSwapFactory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'NomiswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        require(IWETH(WETH).transfer(_getPair(path[0], path[1]), amounts[0]), 'NomiswapRouter: FAILED_TO_TRANSFER');
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'NomiswapRouter: INVALID_PATH');
        amounts = NomiswapLibrary.getAmountsIn(factory, stableSwapFactory, amountOut, path);
        require(amounts[0] <= amountInMax, 'NomiswapRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, _getPair(path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'NomiswapRouter: INVALID_PATH');
        amounts = NomiswapLibrary.getAmountsOut(factory, stableSwapFactory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'NomiswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, _getPair(path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'NomiswapRouter: INVALID_PATH');
        amounts = NomiswapLibrary.getAmountsIn(factory, stableSwapFactory, amountOut, path);
        require(amounts[0] <= msg.value, 'NomiswapRouter: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        require(IWETH(WETH).transfer(_getPair(path[0], path[1]), amounts[0]), 'NomiswapRouter: FAILED_TO_TRANSFER');
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) private {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = NomiswapLibrary.sortTokens(input, output);
            (address _pair, address _factory) = _getPairAndFactory(input, output);
            INomiswapPair pair = INomiswapPair(_pair);
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;

            if (_factory == stableSwapFactory) {
                amountOutput = INomiswapStablePair(_pair).getAmountOut(input, amountInput);
            } else {
                amountOutput = NomiswapLibrary.getConstantProductAmountOut(amountInput, reserveInput, reserveOutput, pair.swapFee());
            }
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? _getPair(output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, _getPair(path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            'NomiswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'NomiswapRouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        require(IWETH(WETH).transfer(_getPair(path[0], path[1]), amountIn), 'NomiswapRouter: FAILED_TO_TRANSFER');
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            'NomiswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'NomiswapRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, _getPair(path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'NomiswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }
}