// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {IUniswapV3Router} from "../interfaces/uniswap-v3/IUniswapV3Router.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {LibRouter, Hop} from "./LibRouter.sol";

library LibUniswapV3 {
    using LibAsset for address;

    function getUniswapV3Path(address[] memory path, bytes32[] memory poolData) private pure returns (bytes memory) {
        bytes memory payload;
        uint256 pathSize = path.length;

        assembly {
            payload := mload(0x40)
            let i := 0
            let payloadPosition := add(payload, 32)
            let pathPosition := add(path, 32)
            let poolDataPosition := add(poolData, 32)

            for {

            } lt(i, pathSize) {
                i := add(i, 1)
                pathPosition := add(pathPosition, 32)
            } {
                mstore(payloadPosition, shl(96, mload(pathPosition)))
                payloadPosition := add(payloadPosition, 20)
                mstore(payloadPosition, mload(poolDataPosition))
                payloadPosition := add(payloadPosition, 3)
                poolDataPosition := add(poolDataPosition, 32)
            }

            mstore(payload, sub(sub(payloadPosition, payload), 32))
            mstore(0x40, and(add(payloadPosition, 31), not(31)))
        }

        return payload;
    }

    function swapUniswapV3(Hop memory h) internal {
        h.path[0].approve(h.addr, h.amountIn);
        if (h.path.length == 2) {
            bytes32 poolData = h.poolData[0];
            uint24 fee;

            assembly {
                fee := shr(232, poolData)
            }

            IUniswapV3Router(h.addr).exactInputSingle(
                IUniswapV3Router.ExactInputSingleParams({
                    tokenIn: h.path[0],
                    tokenOut: h.path[1],
                    fee: fee,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: h.amountIn,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
        } else {
            IUniswapV3Router(h.addr).exactInput(
                IUniswapV3Router.ExactInputParams({
                    path: getUniswapV3Path(h.path, h.poolData),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: h.amountIn,
                    amountOutMinimum: 0
                })
            );
        }
    }
}