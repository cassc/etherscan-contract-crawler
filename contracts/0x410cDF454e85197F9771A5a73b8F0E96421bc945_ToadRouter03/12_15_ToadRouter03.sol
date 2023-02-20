//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;
import "./IToadRouter03.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ToadswapLibrary.sol";
import "./TransferHelper.sol";
import "./IWETH.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC20Permit.sol";
import "./Multicall.sol";
import "./IPermitDai.sol";

/**
 * ToadRouter03
 * A re-implementation of the Uniswap v2 router with bot-driven meta-transactions.
 * Bot private keys are all stored on a hardware wallet.
 * ToadRouter03 implements ERC2612 (ERC20Permit) and auto-unwrap functions
 */
contract ToadRouter03 is IToadRouter03, Ownable, Multicall {
    mapping(address => bool) allowedBots;
    address immutable PERMIT2;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "ToadRouter: EXPIRED");
        _;
    }

    modifier onlyBot() {
        require(allowedBots[_msgSender()], "ToadRouter: UNTRUSTED");
        _;
    }

    constructor(
        address fac,
        address weth,
        address permit
    ) IToadRouter03(fac, weth) {
        // Do any other stuff necessary
        // Add sender to allowedBots
        allowedBots[_msgSender()] = true;
        PERMIT2 = permit;
    }

    function addTrustedBot(address newBot) external onlyOwner {
        allowedBots[newBot] = true;
    }

    function removeTrustedBot(address bot) external onlyOwner {
        allowedBots[bot] = false;
    }

    receive() external payable {
        if (_msgSender() != WETH) {
            revert("ToadRouter: No ETH not from WETH.");
        }
    }

    function performPermit2Single(
        address owner,
        IAllowanceTransfer.PermitSingle memory permitSingle,
        bytes calldata signature
    ) public virtual override onlyBot {
        IAllowanceTransfer permitCA = IAllowanceTransfer(PERMIT2);
        permitCA.permit(owner, permitSingle, signature);
    }

    function performPermit2Batch(
        address owner,
        IAllowanceTransfer.PermitBatch memory permitBatch,
        bytes calldata signature
    ) public virtual override onlyBot {
        IAllowanceTransfer permitCA = IAllowanceTransfer(PERMIT2);
        permitCA.permit(owner, permitBatch, signature);
    }

    function performPermit(
        address owner,
        address tok,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override ensure(deadline) onlyBot {
        IERC20Permit ptok = IERC20Permit(tok);
        ptok.permit(owner, PERMIT2, type(uint256).max, deadline, v, r, s);
    }

    function performPermitDai(address owner, address tok, uint256 nonce, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override onlyBot {
        IPermitDai dpermit = IPermitDai(tok);
        dpermit.permit(owner, PERMIT2, nonce, deadline, true, v, r, s);
    }

    function stfFirstHop(
        uint256 amountIn,
        ToadStructs.DexData memory dex1,
        address path0,
        address path1,
        address to
    ) internal {
        TransferHelper.safeTransferFrom(
            PERMIT2,
            path0,
            to,
            ToadswapLibrary.pairFor(dex1.factory, path0, path1, dex1.initcode),
            amountIn
        );
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokensWithWETHGas(
        uint amountIn,
        uint amountOutMin,
        ToadStructs.AggPath[] calldata path1,
        ToadStructs.AggPath[] calldata path2,
        address to,
        uint deadline,
        ToadStructs.FeeStruct calldata fees,
        ToadStructs.DexData[] calldata dexes
    )
        public
        virtual
        override
        ensure(deadline)
        onlyBot
        returns (uint256 outputAmount)
    {
        // This does two half-swaps, so we can extract the gas return

        // Swap the first half
        TransferHelper.safeTransferFrom(
            PERMIT2,
            path1[0].token,
            to,
            ToadswapLibrary.pairFor(
                dexes[path1[1].dexId].factory,
                path1[0].token,
                path1[1].token,
                dexes[path1[1].dexId].initcode
            ),
            amountIn
        );
        uint256 wethBalanceBefore = IERC20(WETH).balanceOf(address(this));
        // Swap to us
        _swapSupportingFeeOnTransferTokens(path1, address(this), dexes);
        // Extract the WETH to pay the relayer
        IWETH(WETH).withdraw(fees.gasReturn + fees.fee);
        TransferHelper.safeTransferETH(tx.origin, fees.gasReturn);
        if (fees.fee > 0) {
            TransferHelper.safeTransferETH(fees.feeReceiver, fees.fee);
        }
        // Send the remaining WETH to the next hop
        TransferHelper.safeTransfer(
            path2[0].token,
            ToadswapLibrary.pairFor(
                dexes[path2[1].dexId].factory,
                path2[0].token,
                path2[1].token,
                dexes[path1[1].dexId].initcode
            ),
            IERC20(WETH).balanceOf(address(this)) - wethBalanceBefore
        );
        // Grab the pre-balance
        uint256 balanceBefore = IERC20(path2[path2.length - 1].token).balanceOf(
            to
        );
        // Run the final half of swap to the end user
        _swapSupportingFeeOnTransferTokens(path2, to, dexes);
        // Do the output amount check
        outputAmount =
            IERC20(path2[path2.length - 1].token).balanceOf(to) -
            (balanceBefore);
        require(
            outputAmount >= amountOutMin,
            "ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        ToadStructs.AggPath[] calldata path,
        address to,
        uint deadline,
        ToadStructs.FeeStruct calldata fees,
        uint256 ethFee,
        ToadStructs.AggPath[] calldata gasPath,
        ToadStructs.DexData[] calldata dexes
    )
        public
        virtual
        override
        ensure(deadline)
        onlyBot
        returns (uint256 outputAmount)
    {
        if (fees.gasReturn + fees.fee > 0) {
            // Swap the gasReturn tokens from their wallet to us as WETH, unwrap and send to tx origin
            uint balanceBef = IERC20(WETH).balanceOf(address(this));
            stfFirstHop(
                fees.gasReturn + fees.fee,
                dexes[gasPath[1].dexId],
                gasPath[0].token,
                gasPath[1].token,
                to
            );
            _swapSupportingFeeOnTransferTokens(gasPath, address(this), dexes);
            uint256 botAmount = IERC20(WETH).balanceOf(address(this)) -
                balanceBef;
            IWETH(WETH).withdraw(botAmount);
            TransferHelper.safeTransferETH(tx.origin, botAmount - ethFee);
            if (ethFee > 0) {
                TransferHelper.safeTransferETH(fees.feeReceiver, ethFee);
            }
        }

        // Swap remaining tokens to the path provided
        stfFirstHop(
            amountIn - fees.gasReturn - fees.fee,
            dexes[path[1].dexId],
            path[0].token,
            path[1].token,
            to
        );

        uint balanceBefore = IERC20(path[path.length - 1].token).balanceOf(to);

        _swapSupportingFeeOnTransferTokens(path, to, dexes);
        outputAmount =
            IERC20(path[path.length - 1].token).balanceOf(to) -
            (balanceBefore);
        require(
            outputAmount >= amountOutMin,
            "ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactWETHforTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        ToadStructs.AggPath[] calldata path,
        address to,
        uint deadline,
        ToadStructs.FeeStruct calldata fees,
        ToadStructs.DexData[] calldata dexes
    )
        public
        virtual
        override
        ensure(deadline)
        onlyBot
        returns (uint256 outputAmount)
    {
        require(path[0].token == WETH, "ToadRouter: INVALID_PATH");
        // Send us gas first
        if (fees.gasReturn + fees.fee > 0) {
            TransferHelper.safeTransferFrom(
                PERMIT2,
                WETH,
                to,
                address(this),
                fees.gasReturn + fees.fee
            );
            // Pay the relayer
            IWETH(WETH).withdraw(fees.gasReturn + fees.fee);
            TransferHelper.safeTransferETH(tx.origin, fees.gasReturn);
            if (fees.fee > 0) {
                TransferHelper.safeTransferETH(fees.feeReceiver, fees.fee);
            }
        }
        // Send to first pool
        stfFirstHop(
            amountIn - fees.gasReturn - fees.fee,
            dexes[path[1].dexId],
            path[0].token,
            path[1].token,
            to
        );

        uint256 balanceBefore = IERC20(path[path.length - 1].token).balanceOf(
            to
        );
        _swapSupportingFeeOnTransferTokens(path, to, dexes);
        outputAmount =
            IERC20(path[path.length - 1].token).balanceOf(to) -
            (balanceBefore);
        require(
            outputAmount >= amountOutMin,
            "ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactTokensForWETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        ToadStructs.AggPath[] calldata path,
        address to,
        uint deadline,
        ToadStructs.FeeStruct calldata fees,
        ToadStructs.DexData[] calldata dexes,
        bool unwrap
    )
        public
        virtual
        override
        ensure(deadline)
        onlyBot
        returns (uint256 outputAmount)
    {
        require(
            path[path.length - 1].token == WETH,
            "ToadRouter: INVALID_PATH"
        );

        stfFirstHop(
            amountIn,
            dexes[path[1].dexId],
            path[0].token,
            path[1].token,
            to
        );

        _swapSupportingFeeOnTransferTokens(path, address(this), dexes);
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        // Adjust output amount to be exclusive of the payout of gas
        outputAmount = amountOut - fees.gasReturn - fees.fee;
        require(
            outputAmount >= amountOutMin,
            "ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        // Give the WETH to the holder
        if (unwrap) {
            IWETH(WETH).withdraw(outputAmount + fees.gasReturn + fees.fee);
            TransferHelper.safeTransferETH(to, outputAmount);
        } else {
            TransferHelper.safeTransfer(WETH, to, outputAmount);
        }
        // Pay the relayer
        if (fees.gasReturn + fees.fee > 0) {
            if (!unwrap) {
                IWETH(WETH).withdraw(fees.gasReturn + fees.fee);
            }
            TransferHelper.safeTransferETH(tx.origin, fees.gasReturn);
            if (fees.fee > 0) {
                TransferHelper.safeTransferETH(fees.feeReceiver, fees.fee);
            }
        }
    }

    // Gasloan WETH unwrapper
    function unwrapWETH(
        address to,
        uint256 amount,
        ToadStructs.FeeStruct calldata fees
    ) external virtual override onlyBot {
        IERC20(WETH).transferFrom(to, address(this), amount);
        IWETH(WETH).withdraw(amount);
        TransferHelper.safeTransferETH(tx.origin, fees.gasReturn);
        if (fees.fee > 0) {
            TransferHelper.safeTransferETH(fees.feeReceiver, fees.fee);
        }
        TransferHelper.safeTransferETH(to, amount - fees.gasReturn - fees.fee);
    }

    function getPriceOut(
        uint256 amountIn,
        ToadStructs.AggPath[] calldata path,
        ToadStructs.DexData[] calldata dexes
    ) public view virtual override returns (uint256[] memory amounts) {
        return ToadswapLibrary.getPriceOut(amountIn, path, dexes);
    }

    function _swapSupportingFeeOnTransferTokens(
        ToadStructs.AggPath[] memory path,
        address _to,
        ToadStructs.DexData[] memory dexes
    ) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (
                path[i].token,
                path[i + 1].token
            );
            (address token0, ) = ToadswapLibrary.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(
                ToadswapLibrary.pairFor(
                    dexes[path[i + 1].dexId].factory,
                    input,
                    output,
                    dexes[path[i + 1].dexId].initcode
                )
            );
            uint amountInput;
            uint amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1, ) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
                amountInput =
                    IERC20(input).balanceOf(address(pair)) -
                    reserveInput;
                amountOutput = ToadswapLibrary.getAmountOut(
                    amountInput,
                    reserveInput,
                    reserveOutput
                );
            }
            (uint amount0Out, uint amount1Out) = input == token0
                ? (uint(0), amountOutput)
                : (amountOutput, uint(0));
            address to = i < path.length - 2
                ? ToadswapLibrary.pairFor(
                    dexes[path[i + 2].dexId].factory,
                    output,
                    path[i + 2].token,
                    dexes[path[i + 2].dexId].initcode
                )
                : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) public pure virtual override returns (uint amountB) {
        return ToadswapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) public pure virtual override returns (uint amountOut) {
        return ToadswapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) public pure virtual override returns (uint amountIn) {
        return ToadswapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) public view virtual override returns (uint[] memory amounts) {
        // Adjusted to use new code - this is a uniswap-only call
        ToadStructs.AggPath[] memory aggPath = new ToadStructs.AggPath[](
            path.length
        );
        ToadStructs.DexData[] memory dexes = new ToadStructs.DexData[](1);
        dexes[0] = ToadStructs.DexData(
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f",
            factory
        );
        for (uint256 i = 0; i < path.length; i++) {
            aggPath[i] = ToadStructs.AggPath(path[i], 0);
        }
        return ToadswapLibrary.getAmountsOut(amountIn, aggPath, dexes);
    }

    function getAmountsIn(
        uint amountOut,
        address[] memory path
    ) public view virtual override returns (uint[] memory amounts) {
        // Adjusted to use new code - this is a uniswap-only call
        ToadStructs.AggPath[] memory aggPath = new ToadStructs.AggPath[](
            path.length
        );
        ToadStructs.DexData[] memory dexes = new ToadStructs.DexData[](1);
        dexes[0] = ToadStructs.DexData(
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f",
            factory
        );
        for (uint256 i = 0; i < path.length; i++) {
            aggPath[i] = ToadStructs.AggPath(path[i], 0);
        }
        return ToadswapLibrary.getAmountsIn(amountOut, aggPath, dexes);
    }

    function getAmountsOut(
        uint amountIn,
        ToadStructs.AggPath[] calldata path,
        ToadStructs.DexData[] calldata dexes
    ) external view virtual override returns (uint[] memory amounts) {
        return ToadswapLibrary.getAmountsOut(amountIn, path, dexes);
    }

    function getAmountsIn(
        uint amountOut,
        ToadStructs.AggPath[] calldata path,
        ToadStructs.DexData[] calldata dexes
    ) external view virtual override returns (uint[] memory amounts) {
        return ToadswapLibrary.getAmountsIn(amountOut, path, dexes);
    }
}