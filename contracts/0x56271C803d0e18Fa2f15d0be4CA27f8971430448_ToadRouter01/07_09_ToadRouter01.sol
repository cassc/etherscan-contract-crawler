//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;
import "./IToadRouter01.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UniswapV2Library.sol";
import "./TransferHelper.sol";
import "./IWETH.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/**
 * ToadRouter01
 * A re-implementation of the Uniswap v2 router with bot-driven meta-transactions.
 * Bot private keys are all stored on a hardware wallet. 
 */
contract ToadRouter01 is IToadRouter01, Ownable {
    mapping(address => bool) allowedBots;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'ToadRouter: EXPIRED');
        _;
    }


    modifier onlyBot() {
        require(allowedBots[msg.sender], "ToadRouter: UNTRUSTED");
        _;
    }

    constructor(address fac, address weth) IToadRouter01(fac, weth) {
        // Do any other stuff necessary
        // Add sender to allowedBots
        allowedBots[msg.sender] = true;
    }

    function addTrustedBot(address newBot) external onlyOwner {
        allowedBots[newBot] = true;
    }
    function removeTrustedBot(address bot) external onlyOwner {
        allowedBots[bot] = false;
    }

    receive() external payable {
        if(msg.sender != WETH) {
            revert("ToadRouter: No ETH not from WETH.");
        }
    }

    
    // We assume we can swap without fee on transfer here
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 gasReturn,
        address[] calldata gasPath
    ) external virtual override ensure(deadline) onlyBot() returns (uint[] memory amounts) {
        if(gasReturn > 0) {
        // Swap the gasReturn tokens from their wallet to us as WETH, unwrap and send to tx origin
            uint[] memory gasAmounts = UniswapV2Library.getAmountsOut(factory, gasReturn, gasPath);
            TransferHelper.safeTransferFrom(gasPath[0], to, UniswapV2Library.pairFor(factory, gasPath[0], gasPath[1]), gasReturn);
            _swap(gasAmounts, gasPath, address(this));
            IWETH(WETH).withdraw(gasAmounts[gasAmounts.length-1]);
            TransferHelper.safeTransferETH(tx.origin, gasAmounts[gasAmounts.length-1]);
        }
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn-gasReturn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], to, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);

    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 gasReturn,
        address[] calldata gasPath
    ) external virtual override ensure(deadline) onlyBot() returns(uint256 outputAmount) {
        if(gasReturn > 0) {
            // Swap the gasReturn tokens from their wallet to us as WETH, unwrap and send to tx origin
        uint balanceBef = IERC20(WETH).balanceOf(address(this));
        TransferHelper.safeTransferFrom(gasPath[0], to, UniswapV2Library.pairFor(factory, gasPath[0], gasPath[1]), gasReturn);
        _swapSupportingFeeOnTransferTokens(gasPath, address(this));
        outputAmount = IERC20(WETH).balanceOf(address(this)) - balanceBef;
        IWETH(WETH).withdraw(outputAmount);
        TransferHelper.safeTransferETH(tx.origin, outputAmount);
        }
        
        // Swap remaining tokens to the path provided
        TransferHelper.safeTransferFrom(
            path[0], to, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn-gasReturn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - (balanceBefore) >= amountOutMin,
            'ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
        
    }


    function swapExactWETHforTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 gasReturn) external virtual override ensure(deadline) onlyBot() returns(uint256 outputAmount) {
        require(path[0] == WETH, 'ToadRouter: INVALID_PATH');
        // Send us gas first
        if(gasReturn > 0) {
            TransferHelper.safeTransferFrom(WETH, to, address(this), gasReturn);
            // Pay the relayer
            IWETH(WETH).withdraw(gasReturn);
            TransferHelper.safeTransferETH(tx.origin, gasReturn);
        }
        // Send to first pool
        TransferHelper.safeTransferFrom(
            path[0], to, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn-gasReturn
        );
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        outputAmount = IERC20(path[path.length - 1]).balanceOf(to) - (balanceBefore);
        require(
            outputAmount >= amountOutMin,
            'ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );

    }
    function swapExactWETHforTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 gasReturn) external virtual override ensure(deadline) onlyBot() returns (uint[] memory amounts) {
        require(path[0] == WETH, 'ToadRouter: INVALID_PATH');
        // Send us gas first
        TransferHelper.safeTransferFrom(WETH, to, address(this), gasReturn);
        // Do the amount calcs
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn-gasReturn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], to, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
        // Pay gas out
        if(gasReturn > 0) {
            IWETH(WETH).withdraw(gasReturn);
            TransferHelper.safeTransferETH(tx.origin, gasReturn);
        }
    }

    function swapExactTokensForWETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 gasReturn)
        external
        virtual
        override
        ensure(deadline) 
        onlyBot()
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'ToadRouter: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], to, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        TransferHelper.safeTransfer(WETH, to, amounts[amounts.length - 1]-gasReturn);
        // Pay gas
        if(gasReturn > 0) {
            IWETH(WETH).withdraw(gasReturn);
            TransferHelper.safeTransferETH(tx.origin, gasReturn);
        }
        
    }
    
    function swapExactTokensForWETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 gasReturn
    )
        external
        virtual
        override
        ensure(deadline) onlyBot() returns(uint256 outputAmount)
    {
        require(path[path.length - 1] == WETH, 'ToadRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], to, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        // Adjust output amount to be exclusive of the payout of gas
        outputAmount = amountOut - gasReturn;
        require(outputAmount >= amountOutMin, 'ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        // Give the WETH to the holder
        TransferHelper.safeTransfer(WETH, to, outputAmount);
        // Pay the relayer
        IWETH(WETH).withdraw(gasReturn);
        TransferHelper.safeTransferETH(tx.origin, gasReturn);
    }

    // Gasloan WETH unwrapper
    function unwrapWETH(address to, uint256 amount, uint256 gasReturn) onlyBot() external virtual override {
        IERC20(WETH).transferFrom(to, address(this), amount);
        IWETH(WETH).withdraw(amount);
        TransferHelper.safeTransferETH(tx.origin, gasReturn);
        TransferHelper.safeTransferETH(to, amount-gasReturn);
    }



    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }

    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        
        }
    }

    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
            amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    
}