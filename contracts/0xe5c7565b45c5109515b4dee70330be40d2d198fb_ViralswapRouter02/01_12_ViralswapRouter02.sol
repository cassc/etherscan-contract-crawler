// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

/*
BEGIN KEYBASE SALTPACK SIGNED MESSAGE. kXR7VktZdyH7rvq v5weRa0zkYfegFM 5cM6gB7cyPatQvp 6KyygX8PsvQVo4n Ugo6Il5bm5f3Wc6 6TBmPpX0GwuU4n1 jj5f1QNCcPGgXgB 2CnpFgQ3gOEvVg6 XP8CXBnyC9E1gRc gI54di8USKNHywe 5kNeA6zdEcwdKsZ 3Ydod13RrV78Qap G7mca59khDyl2mo iCT5TurbhMcXtFI Z3kVTS4fqbGrGvT RN6eTFmOIlmGzsu 7UUxkeBmUQ5LV5k 9V0AHCX5ZLAjz5f y2Q. END KEYBASE SALTPACK SIGNED MESSAGE.
*/

import './libraries/ViralswapLibrary.sol';
import './libraries/SafeMath.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IViralswapRouter02.sol';
import './interfaces/IUniswapRouter02.sol';
import './interfaces/IViralswapFactory.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';

contract ViralswapRouter02 is IViralswapRouter02 {
    using SafeMathViralswap for uint;

    address public immutable override factory;
    address public immutable override WETH;
    address public immutable override VIRAL;
    address public immutable override altRouter;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'ViralswapRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH, address _VIRAL, address _altRouter) public {
        factory = _factory;
        WETH = _WETH;
        VIRAL = _VIRAL;
        altRouter = _altRouter;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IViralswapFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IViralswapFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = ViralswapLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = ViralswapLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'ViralswapRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = ViralswapLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'ViralswapRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
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
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = ViralswapLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IViralswapPair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = ViralswapLibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IViralswapPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
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
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = ViralswapLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(pair, msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IViralswapPair(pair).burn(to);
        (address token0,) = ViralswapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'ViralswapRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'ViralswapRouter: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
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
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = ViralswapLibrary.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        IViralswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
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
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = ViralswapLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IViralswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
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
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20Viralswap(token).balanceOf(address(this)));
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
    ) external virtual override returns (uint amountETH) {
        address pair = ViralswapLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IViralswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(false, "ViralswapRouter02: Not implemented");
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(false, "ViralswapRouter02: Not implemented");
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(false, "ViralswapRouter02: Not implemented");
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(false, "ViralswapRouter02: Not implemented");
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(false, "ViralswapRouter02: Not implemented");
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(false, "ViralswapRouter02: Not implemented");
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual returns(uint256 finalAmountOutput) {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = ViralswapLibrary.sortTokens(input, output);
            IViralswapPair pair = IViralswapPair(ViralswapLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20Viralswap(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = ViralswapLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? ViralswapLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
            finalAmountOutput = amountOutput;
        }
    }

    /**
     * @dev Function to swap an exact amount of VIRAL for other tokens
     * Leverages the `altRouter` for swaps not concerning VIRAL
     *
     * @param amountIn : the input amount of VIRAL to swap
     * @param amountOutMin : the minimum output amount for tokenOut
     * @param path : [USDC, ..., tokenOut]
     * @param to : the address to receive tokenOut
     * @param deadline : timestamp by which the transaction must complete
    **/
    function swapExactViralForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            VIRAL, msg.sender, ViralswapLibrary.pairFor(factory, VIRAL, path[0]), amountIn
        );
        uint256 balanceBefore = IERC20Viralswap(path[path.length - 1]).balanceOf(to);
        address[] memory fullPath = new address[](2);
        fullPath[0] = VIRAL;
        fullPath[1] = path[0];

        if(path.length == 1) {
            _swapSupportingFeeOnTransferTokens(fullPath, to);
        }
        else {
            uint256 finalAmountOutput = _swapSupportingFeeOnTransferTokens(fullPath, address(this));
            IERC20Viralswap(path[0]).approve(altRouter, finalAmountOutput);
            IUniswapV2Router02(altRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                finalAmountOutput,
                amountOutMin,
                path,
                to,
                deadline
            );
        }

        require(
            IERC20Viralswap(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'ViralswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    /**
     * @dev Function to swap an exact amount of VIRAL for ETH
     * Leverages the `altRouter` for swaps not concerning VIRAL
     *
     * @param amountIn : the input amount of VIRAL to swap
     * @param amountOutMin : the minimum output amount for ETH
     * @param path : [USDC, ..., WETH]
     * @param to : the address to receive ETH
     * @param deadline : timestamp by which the transaction must complete
    **/
    function swapExactViralForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        TransferHelper.safeTransferFrom(
            VIRAL, msg.sender, ViralswapLibrary.pairFor(factory, VIRAL, path[0]), amountIn
        );
        uint256 balanceBefore = to.balance;
        address[] memory fullPath = new address[](2);
        fullPath[0] = VIRAL;
        fullPath[1] = path[0];

        uint256 finalAmountOutput = _swapSupportingFeeOnTransferTokens(fullPath, address(this));
        IERC20Viralswap(path[0]).approve(altRouter, finalAmountOutput);
        IUniswapV2Router02(altRouter).swapExactTokensForETHSupportingFeeOnTransferTokens(
            finalAmountOutput,
            amountOutMin,
            path,
            to,
            deadline
        );

        require(
            to.balance.sub(balanceBefore) >= amountOutMin,
            'ViralswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    /**
     * @dev Function to swap an exact amount of token for VIRAL
     * Leverages the `altRouter` for swaps not concerning VIRAL
     *
     * @param amountIn : the input amount of tokenIn
     * @param amountOutMin : the minimum output amount for VIRAL
     * @param path : [tokenIn, ..., USDC]
     * @param to : the address to receive VIRAL
     * @param deadline : timestamp by which the transaction must complete
    **/
    function swapExactTokensForViralSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        if(path.length == 1) {
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, ViralswapLibrary.pairFor(factory, path[0], VIRAL), amountIn
            );
        }
        else {
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, address(this), amountIn
            );
            address lastToken = path[path.length - 1];
            IERC20Viralswap(path[0]).approve(altRouter, amountIn);
            IUniswapV2Router02(altRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                0,
                path,
                ViralswapLibrary.pairFor(factory, VIRAL, lastToken),
                deadline
            );
        }

        uint256 balanceBefore = IERC20Viralswap(VIRAL).balanceOf(to);
        address[] memory fullPath = new address[](2);
        fullPath[0] = path[path.length - 1];
        fullPath[1] = VIRAL;
        _swapSupportingFeeOnTransferTokens(fullPath, to);
        require(
            IERC20Viralswap(VIRAL).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'ViralswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, ViralswapLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20Viralswap(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20Viralswap(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'ViralswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) {
        require(path[0] == WETH, 'ViralswapRouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(ViralswapLibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20Viralswap(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20Viralswap(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'ViralswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        require(path[path.length - 1] == WETH, 'ViralswapRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, ViralswapLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20Viralswap(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'ViralswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** BUY ****
    // requires the initial amount to have already been sent to the vault
    function _buy(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        require(path.length == 2, 'ViralswapRouter: INVALID_PATH_LENGTH');
        (address input, address output) = (path[0], path[1]);
        IViralswapVault vault = IViralswapVault(ViralswapLibrary.vaultFor(factory, input, output));
        require(input == vault.tokenIn() && output == vault.tokenOut(), 'ViralswapRouter: INCORRECT_PAIR');
        vault.buy(amounts[1], _to);
    }

    /**
     * @dev Function to buy an exact number of tokens from the VIRAL Vault for the specified tokens.
     *
     * @param amountIn : the input amount for tokenIn
     * @param amountOutMin : the minimum output amount for tokenOut (is deterministic since the Vault is a fixed price instrument)
     * @param path : [tokenIn, tokenOut]
     * @param to : the address to receive tokenOut
     * @param deadline : timestamp by which the transaction must complete
    **/
    function buyTokensForExactTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        amounts[1] = ViralswapLibrary.getVaultAmountOut(factory, path[0], path[1], amountIn);
        require(amounts[1] >= amountOutMin, 'ViralswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, ViralswapLibrary.vaultFor(factory, path[0], path[1]), amounts[0]
        );
        _buy(amounts, path, to);
    }

    /**
     * @dev Function to buy VIRAL (using the Vault) from an exact amount of token
     * Leverages the `altRouter` for swaps not concerning VIRAL
     *
     * @param amountIn : the input amount of tokenIn
     * @param amountOutMin : the minimum output amount for VIRAL
     * @param path : [tokenIn, ..., USDC]
     * @param to : the address to receive VIRAL
     * @param deadline : timestamp by which the transaction must complete
    **/
    function buyViralForExactTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        uint256 balanceBeforeIn;
        address lastToken = path[path.length - 1];
        address vault;
        if(path.length == 1) {
            vault = ViralswapLibrary.vaultFor(factory, lastToken, VIRAL);
            balanceBeforeIn = IERC20Viralswap(lastToken).balanceOf(vault);
            TransferHelper.safeTransferFrom(
                lastToken, msg.sender, vault, amountIn
            );
        }
        else {
            vault = ViralswapLibrary.vaultFor(factory, VIRAL, lastToken);
            balanceBeforeIn = IERC20Viralswap(lastToken).balanceOf(vault);

            TransferHelper.safeTransferFrom(
                path[0], msg.sender, address(this), amountIn
            );
            IERC20Viralswap(path[0]).approve(altRouter, amountIn);
            IUniswapV2Router02(altRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                0,
                path,
                vault,
                deadline
            );
        }

        uint256 vaultInTransferred = IERC20Viralswap(lastToken).balanceOf(vault).sub(balanceBeforeIn);
        uint256 balanceBeforeOut = IERC20Viralswap(VIRAL).balanceOf(to);

        address[] memory fullPath = new address[](2);
        fullPath[0] = path[path.length - 1];
        fullPath[1] = VIRAL;

        uint256[] memory amounts = new uint[](2);
        amounts[0] = vaultInTransferred;
        amounts[1] = ViralswapLibrary.getVaultAmountOut(factory, fullPath[0], fullPath[1], vaultInTransferred);

        _buy(amounts, fullPath, to);
        require(
            IERC20Viralswap(VIRAL).balanceOf(to).sub(balanceBeforeOut) >= amountOutMin,
            'ViralswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    /**
     * @dev Function to buy VIRAL (using the Vault) from an exact amount of ETH
     * Leverages the `altRouter` for swaps not concerning VIRAL
     *
     * @param amountOutMin : the minimum output amount for VIRAL
     * @param path : [WETH, ..., USDC]
     * @param to : the address to receive VIRAL
     * @param deadline : timestamp by which the transaction must complete
    **/
    function buyViralForExactETHSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) {
        require(path[0] == WETH, 'ViralswapRouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();

        uint256 balanceBeforeIn;
        address lastToken = path[path.length - 1];
        address vault = ViralswapLibrary.vaultFor(factory, VIRAL, lastToken);
        balanceBeforeIn = IERC20Viralswap(lastToken).balanceOf(vault);

        IERC20Viralswap(path[0]).approve(altRouter, amountIn);
        IUniswapV2Router02(altRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0,
            path,
            vault,
            deadline
        );

        uint256 vaultInTransferred = IERC20Viralswap(lastToken).balanceOf(vault).sub(balanceBeforeIn);
        uint256 balanceBeforeOut = IERC20Viralswap(VIRAL).balanceOf(to);

        address[] memory fullPath = new address[](2);
        fullPath[0] = path[path.length - 1];
        fullPath[1] = VIRAL;

        uint256[] memory amounts = new uint[](2);
        amounts[0] = vaultInTransferred;
        amounts[1] = ViralswapLibrary.getVaultAmountOut(factory, fullPath[0], fullPath[1], vaultInTransferred);

        _buy(amounts, fullPath, to);
        require(
            IERC20Viralswap(VIRAL).balanceOf(to).sub(balanceBeforeOut) >= amountOutMin,
            'ViralswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    // **** LIBRARY FUNCTIONS ****

    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return ViralswapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getVaultAmountOut(address tokenIn, address tokenOut, uint amountIn) public view virtual override returns (uint amountOut) {
        return ViralswapLibrary.getVaultAmountOut(factory, tokenIn, tokenOut, amountIn);
    }

    function getVaultAmountIn(address tokenIn, address tokenOut, uint amountOut) public view virtual override returns (uint amountIn) {
        return ViralswapLibrary.getVaultAmountIn(factory, tokenIn, tokenOut, amountOut);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return ViralswapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return ViralswapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return ViralswapLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return ViralswapLibrary.getAmountsIn(factory, amountOut, path);
    }
}