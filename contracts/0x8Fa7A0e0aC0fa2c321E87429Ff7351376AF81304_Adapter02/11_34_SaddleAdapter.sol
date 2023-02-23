// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../Utils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISwap.sol";

contract SaddleAdapter {
    struct SaddleData {
        uint8 i;
        uint8 j;
        uint256 deadline;
    }

    function swapOnSaddle(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        SaddleData memory data = abi.decode(payload, (SaddleData));

        Utils.approve(address(exchange), address(fromToken), fromAmount);

        ISwap(exchange).swap(data.i, data.j, fromAmount, 1, data.deadline);
    }
}