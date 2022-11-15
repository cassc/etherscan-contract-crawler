// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/router/IUniswapV1Router.sol";
import "../interfaces/router/IUniswapV2Router.sol";
import "../interfaces/router/IUniswapV3Router.sol";
import "../interfaces/router/IBalancerRouter.sol";
import "../interfaces/router/ICurveTC1Router.sol";
import "../interfaces/router/IBancorRouter.sol";
import "../interfaces/router/IDodoRouter.sol";
import "../interfaces/router/IKyberRouter.sol";
import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "@rari-capital/solmate/src/tokens/WETH.sol";

// Import hardhat console
import "hardhat/console.sol";

/// @title Router contract that swaps tokens with different DEXs.
contract MainnetRouter {
    IUniswapV3Router private immutable UniV3Router;
    ICurveTC1Router private immutable curveTC1Router;
    IBalancerRouter private immutable balancer;
    IBancorRouter private immutable bancorRouter;
    IDodoRouter private immutable DodoV2Router;
    address public immutable DODOApproveProxy;
    WETH private immutable WETHContract;
    address private constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint32 public immutable _fee;

    constructor(
        IUniswapV3Router _uniswapV3Router,
        IBalancerRouter _balancer,
        ICurveTC1Router _curveTC1Router,
        IBancorRouter _bancorRouter,
        IDodoRouter _DodoRouter,
        address _dodoApproveProxy,
        address payable _WETHAddress,
        uint32 fee
    ) {
        UniV3Router = _uniswapV3Router;
        balancer = _balancer;
        curveTC1Router = _curveTC1Router;
        bancorRouter = _bancorRouter;
        DodoV2Router = _DodoRouter;
        DODOApproveProxy = _dodoApproveProxy;
        WETHContract = WETH(_WETHAddress);
        _fee = fee;
    }

    struct Amounts {
        uint256 amountIn;
        uint256 amountOutMin;
        uint256 minETH;
    }

    /// @notice Swap tokens using UniV1 router with to address specified
    // NOTE: No input checks - should be checked in the frontend
    /// @param amounts Struct with amountIn, Out, and minEth to avoid stack to deep error
    /// @param path The addresses of tokens to be swapped - source token and destination token
    /// @param pair The pool address for the tokens to be swapped
    /// @param deadline The deadline for the swap
    /// @param to The receiver address
    /// @return amountOut The amount of destination token received
    function uniSwapV1To(
        Amounts memory amounts,
        address[] calldata path,
        address pair,
        uint256 deadline,
        address to,
        bool toETH
    ) public payable returns (uint256 amountOut) {
        if (msg.value != 0) {
            unchecked {
                amountOut = IUniswapV1Router(pair).ethToTokenTransferInput{
                    value: (msg.value * _fee) / 10000
                }(amounts.amountOutMin, deadline, to);
            }
        } else {
            SafeTransferLib.safeTransferFrom(
                ERC20(path[0]),
                msg.sender,
                address(this),
                amounts.amountIn
            );
            unchecked {
                amounts.amountIn = (amounts.amountIn * _fee) / 10000;
            }
            SafeTransferLib.safeApprove(ERC20(path[0]), pair, amounts.amountIn);
            if (toETH) {
                amountOut = IUniswapV1Router(pair).tokenToEthTransferInput(
                    amounts.amountIn,
                    amounts.amountOutMin,
                    deadline,
                    to
                );
            } else {
                amountOut = IUniswapV1Router(pair).tokenToTokenTransferInput(
                    amounts.amountIn,
                    amounts.amountOutMin,
                    amounts.minETH,
                    deadline,
                    to,
                    path[1]
                );
            }
        }
    }

    /// @notice Swap tokens using Sushiswap pool with to address specified
    // NOTE: No input checks - should be checked in the frontend
    /// @param amountIn The amount of source token to be swapped
    /// @param amountOutMin The minimum amount of destination token to be received
    /// @param path The addresses of tokens to be swapped - source token and destination token
    /// @param deadline The deadline for the swap
    /// @param to The receiver address
    /// @param router The address for the router being that forked UniV2 e.g. UniV2. Sushiswap, PancakeSwap etc.
    /// @return amountOut The amount of destination token received
    function uniSwapV2To(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline,
        address to,
        IUniswapV2Router router
    ) public payable returns (uint256 amountOut) {
        uint256[] memory amounts;
        if (msg.value != 0) {
            unchecked {
                amounts = router.swapExactETHForTokens{
                    value: (msg.value * _fee) / 10000
                }(amountOutMin, path, to, deadline);
            }
        } else {
            bool ToETH = path[1] == address(0);
            SafeTransferLib.safeTransferFrom(
                ERC20(path[0]),
                msg.sender,
                address(this),
                amountIn
            );
            unchecked {
                amountIn = (amountIn * _fee) / 10000;
            }
            SafeTransferLib.safeApprove(
                ERC20(path[0]),
                address(router),
                amountIn
            );
            if (!ToETH) {
                amounts = router.swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path,
                    to,
                    deadline
                );
            } else {
                path[1] = address(WETHContract);
                amounts = router.swapExactTokensForETH(
                    amountIn,
                    amountOutMin,
                    path,
                    to,
                    deadline
                );
            }
        }
        return amounts[1];
    }

    /// @notice Swap tokens using UniV3 router with to address specified
    // NOTE: No input checks - should be checked in the frontend
    /// @param amountIn The amount of source token to be swapped
    /// @param amountOutMin The minimum amount of destination token to be received
    /// @param path The addresses of tokens to be swapped - source token and destination token
    /// @param deadline The deadline for the swap
    /// @param fee The fee for the pool being swapped with
    /// @param to The receiver address
    /// @return amountOut The amount of destination token received
    function uniSwapV3To(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline,
        uint24 fee,
        address payable to
    ) public payable returns (uint256 amountOut) {
        if (msg.value != 0) {
            unchecked {
                amountIn = (msg.value * _fee) / 10000;
            }
            WETHContract.deposit{value: amountIn}();
            SafeTransferLib.safeApprove(
                ERC20(path[0]),
                address(UniV3Router),
                amountIn
            );
            amountOut = UniV3Router.exactInputSingle(
                IUniswapV3Router.ExactInputSingleParams(
                    path[0],
                    path[1],
                    fee,
                    to,
                    deadline,
                    amountIn,
                    amountOutMin,
                    0
                )
            );
        } else {
            SafeTransferLib.safeTransferFrom(
                ERC20(path[0]),
                msg.sender,
                address(this),
                amountIn
            );
            unchecked {
                amountIn = (amountIn * _fee) / 10000;
            }
            SafeTransferLib.safeApprove(
                ERC20(path[0]),
                address(UniV3Router),
                amountIn
            );
            bool toETH = path[1] == address(0);
            if (!toETH) {
                amountOut = UniV3Router.exactInputSingle(
                    IUniswapV3Router.ExactInputSingleParams(
                        path[0],
                        path[1],
                        fee,
                        to,
                        deadline,
                        amountIn,
                        amountOutMin,
                        0
                    )
                );
            } else {
                amountOut = UniV3Router.exactInputSingle(
                    IUniswapV3Router.ExactInputSingleParams(
                        path[0],
                        address(WETHContract),
                        fee,
                        address(this),
                        deadline,
                        amountIn,
                        amountOutMin,
                        0
                    )
                );
                WETHContract.withdraw(amountOut);
                SafeTransferLib.safeTransferETH(to, amountOut);
            }
        }
    }

    /// @notice Swap tokens using Balancer router with to specified
    // NOTE: No input checks - should be checked in the frontend
    /// @param amountIn The amount of source token to be swapped
    /// @param amountOutMin The minimum amount of destination token to be received
    /// @param path The addresses of tokens to be swapped
    /// @param deadline The deadline for the swap
    /// @param poolId The id for the balancer pool
    /// @param to The receiver address
    /// @return amountOut The amount of destination token received from the swap
    function balancerSwapTo(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline,
        bytes32 poolId,
        address payable to
    ) public payable returns (uint256 amountOut) {
        SafeTransferLib.safeTransferFrom(
            ERC20(path[0]),
            msg.sender,
            address(this),
            amountIn
        );
        unchecked {
            amountIn = (amountIn * _fee) / 10000;
        }
        SafeTransferLib.safeApprove(
            ERC20(path[0]),
            address(balancer),
            amountIn
        );
        amountOut = balancer.swap(
            IBalancerRouter.SingleSwap({
                poolId: poolId,
                kind: IBalancerRouter.SwapKind.GIVEN_IN,
                assetIn: path[0],
                assetOut: path[1],
                amount: amountIn,
                userData: "0x"
            }),
            IBalancerRouter.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: to,
                toInternalBalance: false
            }),
            amountOutMin,
            deadline
        );
    }

    /// @notice Swap tokens using Curve router with to address specified
    // NOTE: No input checks - should be checked in the frontend
    /// @param amountIn The amount of source token to be swapped
    /// @param amountOutMin The minimum amount of destination token to be received
    /// @param path The addresses of tokens to be swapped - token A and token B
    /// @param pair The pool address for the tokens to be swapped
    /// @param to The receiver address
    /// @return amountOut The amount of destination token received
    function curveSwapTo(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address pair,
        address to
    ) public payable returns (uint256 amountOut) {
        if (msg.value != 0) {
            unchecked {
                amountIn = (msg.value * _fee) / 10000;
                amountOut = curveTC1Router.exchange{value: amountIn}(
                    pair,
                    path[0],
                    path[1],
                    amountIn,
                    amountOutMin,
                    to
                );
            }
        } else {
            SafeTransferLib.safeTransferFrom(
                ERC20(path[0]),
                msg.sender,
                address(this),
                amountIn
            );
            unchecked {
                amountIn = (amountIn * _fee) / 10000;
            }
            SafeTransferLib.safeApprove(
                ERC20(path[0]),
                address(curveTC1Router),
                amountIn
            );
            amountOut = curveTC1Router.exchange(
                pair,
                path[0],
                path[1],
                amountIn,
                amountOutMin,
                to
            );
        }
    }

    /// @notice Swap tokens using UniV2 router with to address specified
    // NOTE: No input checks - should be checked in the frontend
    /// @param amountIn The amount of source token to be swapped
    /// @param amountOutMin The minimum amount of destination token to be received
    /// @param path The addresses of tokens to be swapped - source token and destination token
    /// @param deadline The deadline for the swap
    /// @param to The receiver address
    /// @return amountOut The amount of destination token received
    function bancorSwapTo(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline,
        address to
    ) public payable returns (uint256 amountOut) {
        if (msg.value != 0) {
            unchecked {
                amountIn = (msg.value * _fee) / 10000;
                amountOut = bancorRouter.tradeBySourceAmount{value: amountIn}(
                    path[0],
                    path[1],
                    amountIn,
                    amountOutMin,
                    deadline,
                    to
                );
            }
        } else {
            SafeTransferLib.safeTransferFrom(
                ERC20(path[0]),
                msg.sender,
                address(this),
                amountIn
            );
            unchecked {
                amountIn = (amountIn * _fee) / 10000;
            }
            SafeTransferLib.safeApprove(
                ERC20(path[0]),
                address(bancorRouter),
                amountIn
            );
            amountOut = bancorRouter.tradeBySourceAmount(
                path[0],
                path[1],
                amountIn,
                amountOutMin,
                deadline,
                to
            );
        }
    }

    /// @notice Swap tokens using UniV2 router with to address specified
    // NOTE: No input checks - should be checked in the frontend
    /// @param amountIn The amount of source token to be swapped
    /// @param amountOutMin The minimum amount of destination token to be received
    /// @param path The addresses of tokens to be swapped - source token and destination token
    /// @param deadline The deadline for the swap
    /// @param to The receiver address
    /// @return amountOut The amount of destination token received
    function dodoSwapTo(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address[] calldata pair,
        uint256 deadline,
        uint256 direction,
        address to
    ) public payable returns (uint256 amountOut) {
        if (msg.value != 0) {
            amountOut = DodoV2Router.dodoSwapV2ETHToToken{
                value: (msg.value * _fee) / 10000
            }(path[1], amountOutMin, pair, direction, false, deadline);
            SafeTransferLib.safeTransfer(ERC20(path[1]), to, amountOut);
        } else {
            bool toETH = path[1] == address(0);
            SafeTransferLib.safeTransferFrom(
                ERC20(path[0]),
                msg.sender,
                address(this),
                amountIn
            );
            unchecked {
                amountIn = (amountIn * _fee) / 10000;
            }
            SafeTransferLib.safeApprove(
                ERC20(path[0]),
                DODOApproveProxy,
                amountIn
            );
            if (toETH) {
                amountOut = DodoV2Router.dodoSwapV2TokenToETH(
                    path[0],
                    amountIn,
                    amountOutMin,
                    pair,
                    direction,
                    false,
                    deadline
                );
                SafeTransferLib.safeTransferETH(to, amountOut);
            } else {
                amountOut = DodoV2Router.dodoSwapV2TokenToToken(
                    path[0],
                    path[1],
                    amountIn,
                    amountOutMin,
                    pair,
                    direction,
                    false,
                    deadline
                );
                SafeTransferLib.safeTransfer(ERC20(path[1]), to, amountOut);
            }
        }
    }

    /// @notice Swap tokens using UniV3 router with to address specified
    // NOTE: No input checks - should be checked in the frontend
    /// @param amountIn The amount of source token to be swapped
    /// @param amountOutMin The minimum amount of destination token to be received
    /// @param path The addresses of tokens to be swapped - source token and destination token
    /// @param deadline The deadline for the swap
    /// @param fee The fee for the pool being swapped with
    /// @param to The receiver address
    /// @return amountOut The amount of destination token received
    function kyberSwapTo(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline,
        uint24 fee,
        IKyberRouter router,
        address payable to
    ) public payable returns (uint256 amountOut) {
        if (msg.value != 0) {
            unchecked {
                amountIn = (msg.value * _fee) / 10000;
            }
            WETHContract.deposit{value: amountIn}();
            SafeTransferLib.safeApprove(
                ERC20(path[0]),
                address(router),
                amountIn
            );
            amountOut = router.swapExactInputSingle(
                IKyberRouter.ExactInputSingleParams(
                    path[0],
                    path[1],
                    fee,
                    to,
                    deadline,
                    amountIn,
                    amountOutMin,
                    0
                )
            );
        } else {
            SafeTransferLib.safeTransferFrom(
                ERC20(path[0]),
                msg.sender,
                address(this),
                amountIn
            );
            unchecked {
                amountIn = (amountIn * _fee) / 10000;
            }
            bool toETH = path[1] == address(0);
            SafeTransferLib.safeApprove(
                ERC20(path[0]),
                address(router),
                amountIn
            );
            if (!toETH) {
                amountOut = router.swapExactInputSingle(
                    IKyberRouter.ExactInputSingleParams(
                        path[0],
                        path[path.length - 1],
                        fee,
                        to,
                        deadline,
                        amountIn,
                        amountOutMin,
                        0
                    )
                );
            } else {
                amountOut = router.swapExactInputSingle(
                    IKyberRouter.ExactInputSingleParams(
                        path[0],
                        address(WETHContract),
                        fee,
                        address(this),
                        deadline,
                        amountIn,
                        amountOutMin,
                        0
                    )
                );
                WETHContract.withdraw(amountOut);
                SafeTransferLib.safeTransferETH(to, amountOut);
            }
        }
    }

    ////////////////////////////////////////// ADMIN FUNCTIONS //////////////////////////////////////////

    /// @notice Flushes the balance of the contract for a token to an address
    /// @param _token The address of the token to be flushed
    /// @param _to The address to which the balance will be flushed
    function flush(ERC20 _token, address _to) external {
        uint256 amount = _token.balanceOf(address(this));
        assembly {
            if iszero(
                eq(caller(), 0x123CB0304c7f65B0D48276b9857F4DF4733d1dd8) // Required address to flush
            ) {
                revert(0, 0)
            }
            // We'll write our calldata to this slot.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with function selector
            mstore(0x00, 0xa9059cbb)
            mstore(0x20, _to) // append the 'to' argument
            mstore(0x40, amount) // append the 'amount' argument

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x64 because that's the total length of our call data (0x04 + 0x20 * 3)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), _token, 0, 0x1c, 0x60, 0x00, 0x20)
                    // Adjusted above by changing 0x64 to 0x60
                )
            ) {
                // Store the function selector of TransferFromFailed()
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size)
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero
            mstore(0x40, memPointer) // Restore the mempointer
        }
    }

    /// @notice Flushes the ETH balance of the contract to an address
    /// @param to The address to which the balance will be flushed
    function flushETH(address to) external {
        uint256 amount = address(this).balance;
        assembly {
            if iszero(
                eq(caller(), 0x123CB0304c7f65B0D48276b9857F4DF4733d1dd8) // Required address to flush
            ) {
                revert(0, 0)
            }
            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x64 because that's the total length of our call data (0x04 + 0x20 * 3)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), to, amount, 0, 0, 0, 0)
                    // Adjusted above by changing 0x64 to 0x60
                )
            ) {
                // Store the function selector of TransferFromFailed()
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size)
                revert(0x1c, 0x04)
            }
        }
    }

    /// @notice receive fallback function for empty call data
    receive() external payable {}

    /// @notice fallback function when no other function matches
    fallback() external payable {}
}