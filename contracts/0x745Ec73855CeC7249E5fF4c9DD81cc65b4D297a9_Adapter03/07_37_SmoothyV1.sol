// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";
import "./ISmoothyV1.sol";
import "../weth/IWETH.sol";

contract SmoothyV1 {
    struct SmoothyV1Data {
        uint256 i;
        uint256 j;
    }

    function swapOnSmoothyV1(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        SmoothyV1Data memory data = abi.decode(payload, (SmoothyV1Data));

        Utils.approve(exchange, address(fromToken), fromAmount);

        ISmoothyV1(exchange).swap(data.i, data.j, fromAmount, 1);
    }
}