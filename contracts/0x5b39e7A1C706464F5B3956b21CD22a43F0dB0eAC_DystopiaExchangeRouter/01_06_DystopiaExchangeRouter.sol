// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "../../weth/IWETH.sol";
import "./IDystPair.sol";

contract DystopiaExchangeRouter {
    using SafeMath for uint256;

    /*solhint-disable var-name-mixedcase*/
    address private constant ETH_IDENTIFIER = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    // Pool bits are 255-161: fee, 160: direction flag, 159-0: address
    uint256 private constant FEE_OFFSET = 161;
    uint256 private constant DIRECTION_FLAG = 0x0000000000000000000000010000000000000000000000000000000000000000;

    /*solhint-enable var-name-mixedcase */

    /*solhint-disable no-empty-blocks */
    receive() external payable {}

    /*solhint-enable no-empty-blocks */

    function swap(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address weth,
        uint256[] calldata pools
    ) external payable returns (uint256 tokensBought) {
        return _swap(tokenIn, amountIn, amountOutMin, weth, pools);
    }

    function _swap(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address weth,
        uint256[] memory pools
    ) private returns (uint256 tokensBought) {
        uint256 pairs = pools.length;

        require(pairs != 0, "At least one pool required");

        bool tokensBoughtEth;

        if (tokenIn == ETH_IDENTIFIER) {
            require(amountIn == msg.value, "Incorrect amount of ETH sent");
            IWETH(weth).deposit{ value: msg.value }();
            require(IWETH(weth).transfer(address(pools[0]), msg.value));
        } else {
            TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(pools[0]), amountIn);
            tokensBoughtEth = weth != address(0);
        }

        tokensBought = amountIn;

        for (uint256 i = 0; i < pairs; ++i) {
            uint256 p = pools[i];
            address pool = address(uint160(p));
            bool direction = p & DIRECTION_FLAG == 0;

            address tokenA = direction ? IDystPair(pool).token0() : IDystPair(pool).token1();
            tokensBought = IDystPair(pool).getAmountOut(tokensBought, tokenA);

            if (IDystPair(pool).stable()) {
                tokensBought = tokensBought.sub(100); // deduce 100wei to mitigate stable swap's K miscalculations
            }

            (uint256 amount0Out, uint256 amount1Out) = direction
                ? (uint256(0), tokensBought)
                : (tokensBought, uint256(0));
            IDystPair(pool).swap(
                amount0Out,
                amount1Out,
                i + 1 == pairs ? (tokensBoughtEth ? address(this) : msg.sender) : address(pools[i + 1]),
                ""
            );
        }

        if (tokensBoughtEth) {
            IWETH(weth).withdraw(tokensBought);
            TransferHelper.safeTransferETH(msg.sender, tokensBought);
        }

        require(tokensBought >= amountOutMin, "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
    }
}