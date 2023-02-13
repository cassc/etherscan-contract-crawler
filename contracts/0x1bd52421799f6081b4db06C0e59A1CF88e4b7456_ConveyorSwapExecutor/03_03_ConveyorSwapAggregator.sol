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

    struct SwapAggregatorMulticall {
        address tokenInDestination;
        Call[] calls;
    }

    struct Call {
        address target;
        bytes callData;
    }

    function swap(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOutMin,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external {
        IERC20(tokenIn).transferFrom(
            msg.sender,
            swapAggregatorMulticall.tokenInDestination,
            amountIn
        );

        uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(msg.sender);
        uint256 tokenOutAmountRequired = tokenOutBalance + amountOutMin;

        IConveyorSwapExecutor(CONVEYOR_SWAP_EXECUTOR).executeMulticall(
            swapAggregatorMulticall.calls
        );

        if (IERC20(tokenOut).balanceOf(msg.sender) < tokenOutAmountRequired) {
            revert InsufficientOutputAmount(
                tokenOutAmountRequired - IERC20(tokenOut).balanceOf(msg.sender),
                amountOutMin
            );
        }
    }

    function swapExactEthForToken(
        address tokenOut,
        uint256 amountOutMin,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable {
        address _weth = WETH;
        assembly {
            mstore(0x0, shl(224, 0xd0e30db0))
            if iszero(
                call(
                    gas(),
                    _weth,
                    callvalue(),
                    0,
                    0,
                    0,
                    0
                )
            ) {
                revert("Native token deposit failed", 0)
            }
            
        }
      
        IERC20(WETH).transfer(
            swapAggregatorMulticall.tokenInDestination,
            msg.value
        );

        uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(msg.sender);
        uint256 tokenOutAmountRequired = tokenOutBalance + amountOutMin;

        IConveyorSwapExecutor(CONVEYOR_SWAP_EXECUTOR).executeMulticall(
            swapAggregatorMulticall.calls
        );

        bool sufficient;
        uint256 balanceOut = IERC20(tokenOut).balanceOf(msg.sender);

        assembly {
            sufficient := iszero(lt(tokenOutAmountRequired, balanceOut))
        }
        
        if (!sufficient) {
            revert InsufficientOutputAmount(
                tokenOutAmountRequired - balanceOut,
                amountOutMin
            );
        }
    }

    function swapExactTokenForEth(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external {
        IERC20(tokenIn).transferFrom(
            msg.sender,
            swapAggregatorMulticall.tokenInDestination,
            amountIn
        );

        uint256 amountOutRequired;
        assembly {
            amountOutRequired := add(selfbalance(), amountOutMin)
        }

        IConveyorSwapExecutor(CONVEYOR_SWAP_EXECUTOR).executeMulticall(
            swapAggregatorMulticall.calls
        );

        bool sufficient;
        bool transferSuccess;
        uint256 balanceWeth = IERC20(WETH).balanceOf(address(this));

        address _weth = WETH;
        assembly {
            mstore(0x0, shl(224, 0x2e1a7d4d))
            mstore(4, balanceWeth)
            if iszero(
                call(
                    gas(),
                    _weth,
                    0, /* wei */
                    0, /* in pos */
                    68, /* in len */
                    0, /* out pos */
                    0 /* out size */
                )
            ) {
                revert("Native Token Withdraw failed", balanceWeth)
            }

            sufficient := iszero(lt(amountOutRequired, selfbalance()))

            if sufficient {
                mstore(
                    0x00,
                    0xa9059cbb00000000000000000000000000000000000000000000000000000000
                )

                mstore(4, caller())
                mstore(36, selfbalance())

                pop(
                    call(
                        gas(),
                        0, /* to */
                        0, /* wei */
                        0, /* in pos */
                        68, /* in len */
                        0, /* out pos */
                        0 /* out size */
                    )
                )
                transferSuccess := iszero(returndatasize())
            }
        }

        if (!sufficient) {
            revert InsufficientOutputAmount(
                amountOutRequired - address(this).balance,
                amountOutMin
            );
        }

        require(transferSuccess, "Native transfer failed");
    }

    receive() external payable {}
}

contract ConveyorSwapExecutor {
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