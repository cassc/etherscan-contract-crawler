// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";
import "../../interfaces/IWETH9.sol";


abstract contract SwapToUSDC {
    using BytesLib for bytes;

    ISwapRouter immutable public uniswapRouter;
    IQuoter     immutable public uniswapQuoter;
    IWETH9      immutable public WETH;
    IERC20      immutable public USDC;

    constructor(ISwapRouter uniswapRouter_, IQuoter uniswapQuoter_, IERC20 USDC_) {
        uniswapRouter = uniswapRouter_;
        uniswapQuoter = uniswapQuoter_;
        USDC          = USDC_;
        WETH          = IWETH9(IPeripheryImmutableState(address(uniswapRouter_)).WETH9());
    }

    function _swap(address receiver_, uint256 amountIn_, uint256 amountOutMinimum_, uint256 amountOutMaximum_, bytes memory path_) internal returns (uint256) {
        // Set override for ETH / Check path
        if (msg.value > 0) {
            // if we have value, force WETH <> USDC swap
            amountIn_ = msg.value;
            path_     = abi.encodePacked(WETH, uint24(3000), USDC);
        } else if (path_.length > 0) {
            require(IERC20(path_.toAddress(path_.length - 20)) == USDC, "invalid-token-output");
        }

        // don't swap to much
        if (amountOutMaximum_ < type(uint256).max) {
            if (path_.length == 0) {
                // If no path, we are dealing with USDC everywhere
                amountIn_ = Math.min(amountIn_, amountOutMaximum_);
            } else {
                // Otherwize use the quoter: note that this may revert, in which case we disregard the check
                try uniswapQuoter.quoteExactOutput(reversePath(path_), amountOutMaximum_) returns (uint256 amountInMax) {
                    amountIn_ = Math.min(amountIn_, amountInMax);
                } catch {}
            }
        }

        // No value and a path, we need to take custody of the token and approve the router
        if (msg.value == 0 && path_.length > 0) {
            IERC20 assetIn  = IERC20(path_.toAddress(0));
            SafeERC20.safeTransferFrom(assetIn, msg.sender, address(this), amountIn_);
            SafeERC20.safeApprove(assetIn, address(uniswapRouter), amountIn_);
        }

        if (path_.length == 0) {
            SafeERC20.safeTransferFrom(
                USDC,
                msg.sender,
                receiver_,
                amountIn_
            );
            return amountIn_;
        } else {
            return uniswapRouter.exactInput{ value: msg.value == 0 ? 0 : amountIn_ }(ISwapRouter.ExactInputParams({
                path:              path_,
                recipient:         receiver_,
                deadline:          block.timestamp,
                amountIn:          amountIn_,
                amountOutMinimum:  amountOutMinimum_
            }));
        }
    }
}

function reversePath(bytes memory path) pure returns (bytes memory) {
    uint256      count = (path.length - 20) / 23;
    bytes memory rpath = new bytes(path.length);
    assembly {
        let pathOffset  := mul(count, 0x17)
        let rpathOffset := 0
        for {}
            gt(pathOffset, 0)
            {
                pathOffset  := sub(pathOffset, 0x17)
                rpathOffset := add(rpathOffset, 0x17)
            }
            {
                let buffer := mload(add(path, add(pathOffset, 0x1D)))
                mstore(
                    add(rpath, add(rpathOffset, 0x20)),
                    shl(0x18, and(buffer, 0x000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000))
                )
                mstore(
                    add(rpath, add(rpathOffset, 0x34)),
                    and(buffer, 0xFFFFFF0000000000000000000000000000000000000000000000000000000000)
                )
            }
        mstore(
            add(rpath, add(rpathOffset, 0x20)),
            and(mload(add(path, 0x20)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000)
        )
    }
    return rpath;
}