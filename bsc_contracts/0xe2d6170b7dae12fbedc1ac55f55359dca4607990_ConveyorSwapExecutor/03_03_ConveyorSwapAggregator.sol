// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../lib/interfaces/token/IERC20.sol";
import "./ConveyorErrors.sol";

interface IConveyorSwapExecutor {
    function executeMulticall(ConveyorSwapAggregator.Call[] memory calls)
        external;
}

/// @title ConveyorSwapAggregator
/// @author 0xKitsune, 0xOsiris, Conveyor Labs
/// @notice Multicall contract for token Swaps.
contract ConveyorSwapAggregator {
    address public immutable CONVEYOR_SWAP_EXECUTOR;
    address public immutable WETH;

    constructor(address _weth) {
        WETH = _weth;
        CONVEYOR_SWAP_EXECUTOR = address(new ConveyorSwapExecutor());
    }

    /// @notice Multicall struct for token Swaps.
    /// @param tokenInDestination Address to send tokenIn to.
    /// @param calls Array of calls to be executed.
    struct SwapAggregatorMulticall {
        address tokenInDestination;
        Call[] calls;
    }
    /// @notice Call struct for token Swaps.
    /// @param target Address to call.
    /// @param callData Data to call.
    struct Call {
        address target;
        bytes callData;
    }

    /// @notice Swap tokens for tokens.
    /// @param tokenIn Address of token to swap.
    /// @param amountIn Amount of tokenIn to swap.
    /// @param tokenOut Address of token to receive.
    /// @param amountOutMin Minimum amount of tokenOut to receive.
    /// @param swapAggregatorMulticall Multicall to be executed.
    function swap(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOutMin,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external {
        ///@notice Transfer tokenIn from msg.sender to tokenInDestination address.
        IERC20(tokenIn).transferFrom(
            msg.sender,
            swapAggregatorMulticall.tokenInDestination,
            amountIn
        );

        ///@notice Get tokenOut balance of msg.sender.
        uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(msg.sender);
        ///@notice Calculate tokenOut amount required.
        uint256 tokenOutAmountRequired = tokenOutBalance + amountOutMin;

        ///@notice Execute Multicall.
        IConveyorSwapExecutor(CONVEYOR_SWAP_EXECUTOR).executeMulticall(
            swapAggregatorMulticall.calls
        );
        ///@notice Check if tokenOut balance of msg.sender is sufficient.
        if (IERC20(tokenOut).balanceOf(msg.sender) < tokenOutAmountRequired) {
            revert InsufficientOutputAmount(
                tokenOutAmountRequired - IERC20(tokenOut).balanceOf(msg.sender),
                amountOutMin
            );
        }
    }

    /// @notice Swap ETH for tokens.
    /// @param tokenOut Address of token to receive.
    /// @param amountOutMin Minimum amount of tokenOut to receive.
    /// @param swapAggregatorMulticall Multicall to be executed.
    function swapExactEthForToken(
        address tokenOut,
        uint256 amountOutMin,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable {
        ///@notice Deposit the msg.value into WETH.
        address _weth = WETH;
        assembly {
            mstore(0x0, shl(224, 0xd0e30db0)) /* keccak256("deposit()") */
            if iszero(
                call(
                    gas(), /* gas */
                    _weth, /* to */
                    callvalue(), /* value */
                    0, /* in */
                    0, /* in size */
                    0, /* out */
                    0 /* out size */
                )
            ) {
                revert("Native token deposit failed", 0)
            }
        }

        ///@notice Transfer WETH from WETH to tokenInDestination address.
        IERC20(WETH).transfer(
            swapAggregatorMulticall.tokenInDestination,
            msg.value
        );

        ///@notice Get tokenOut balance of msg.sender.
        uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(msg.sender);
        ///@notice Calculate tokenOut amount required.
        uint256 tokenOutAmountRequired = tokenOutBalance + amountOutMin;

        ///@notice Execute Multicall.
        IConveyorSwapExecutor(CONVEYOR_SWAP_EXECUTOR).executeMulticall(
            swapAggregatorMulticall.calls
        );

        bool sufficient;

        ///@notice Get tokenOut balance of msg.sender after multicall execution.
        uint256 balanceOut = IERC20(tokenOut).balanceOf(msg.sender);

        // Check if tokenOut balance of msg.sender is sufficient.
        assembly {
            sufficient := not(gt(tokenOutAmountRequired, balanceOut))
        }

        ///@notice Revert if tokenOut balance of msg.sender is insufficient.
        if (!sufficient) {
            revert InsufficientOutputAmount(
                tokenOutAmountRequired - balanceOut,
                amountOutMin
            );
        }
    }

    /// @notice Swap tokens for ETH.
    /// @param tokenIn Address of token to swap.
    /// @param amountIn Amount of tokenIn to swap.
    /// @param amountOutMin Minimum amount of ETH to receive.
    /// @param swapAggregatorMulticall Multicall to be executed.
    function swapExactTokenForEth(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external {
        ///@notice Transfer tokenIn from msg.sender to tokenInDestination address.
        IERC20(tokenIn).transferFrom(
            msg.sender,
            swapAggregatorMulticall.tokenInDestination,
            amountIn
        );
        ///@notice Calculate amountOutRequired.
        uint256 amountOutRequired;
        assembly {
            amountOutRequired := add(balance(caller()), amountOutMin)
        }
        ///@notice Execute Multicall.
        IConveyorSwapExecutor(CONVEYOR_SWAP_EXECUTOR).executeMulticall(
            swapAggregatorMulticall.calls
        );

        ///@notice Get WETH balance of this contract.
        uint256 balanceWeth = IERC20(WETH).balanceOf(address(this));

        ///@notice Withdraw WETH from this contract.
        address _weth = WETH;
        assembly {
            mstore(0x0, shl(224, 0x2e1a7d4d)) /* keccak256("withdraw(uint256)") */
            mstore(4, balanceWeth)
            if iszero(
                call(
                    gas(), /* gas */
                    _weth, /* to */
                    0, /* value */
                    0, /* in */
                    68, /* in size */
                    0, /* out */
                    0 /* out size */
                )
            ) {
                revert("Native Token Withdraw failed", balanceWeth)
            }
        }

        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), caller(), selfbalance(), 0, 0, 0, 0)
        }

        if (!success) {
            revert ETHTransferFailed();
        }


        ///@notice Revert if Eth balance of the caller is insufficient.
        if (msg.sender.balance < amountOutRequired) {
            revert InsufficientOutputAmount(
                amountOutRequired - msg.sender.balance,
                amountOutMin
            );
        }
    }

    receive() external payable {}
}


contract ConveyorSwapExecutor {
    ///@notice Executes a multicall.
    function executeMulticall(ConveyorSwapAggregator.Call[] calldata calls)
        public
    {
        uint256 callsLength = calls.length;
        for (uint256 i = 0; i < callsLength; ) {
            ConveyorSwapAggregator.Call memory call = calls[i];

            (bool success, ) = call.target.call(call.callData);

            require(success, "call failed");

            unchecked {
                ++i;
            }
        }
    }

    ///@notice Uniswap V3 callback function called during a swap on a v3 liqudity pool.
    ///@param amount0Delta - The change in token0 reserves from the swap.
    ///@param amount1Delta - The change in token1 reserves from the swap.
    ///@param data - The data packed into the swap.
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        ///@notice Decode all of the swap data.
        (bool _zeroForOne, address tokenIn, address _sender) = abi.decode(
            data,
            (bool, address, address)
        );

        ///@notice Set amountIn to the amountInDelta depending on boolean zeroForOne.
        uint256 amountIn = _zeroForOne
            ? uint256(amount0Delta)
            : uint256(amount1Delta);

        if (!(_sender == address(this))) {
            ///@notice Transfer the amountIn of tokenIn to the liquidity pool from the sender.
            IERC20(tokenIn).transferFrom(_sender, msg.sender, amountIn);
        } else {
            IERC20(tokenIn).transfer(msg.sender, amountIn);
        }
    }
}