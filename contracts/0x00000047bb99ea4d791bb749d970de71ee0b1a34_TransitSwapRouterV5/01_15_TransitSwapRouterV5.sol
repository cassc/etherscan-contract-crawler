// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UniswapV2Router.sol";
import "./UniswapV3Router.sol";
import "./AggregateRouter.sol";
import "./CrossRouter.sol";

contract TransitSwapRouterV5 is UniswapV2Router, UniswapV3Router, AggregateRouter, CrossRouter  {

    function withdrawTokens(address[] memory tokens, address recipient) external onlyExecutor {
        for (uint index; index < tokens.length; index++) {
            uint amount;
            if (TransferHelper.isETH(tokens[index])) {
                amount = address(this).balance;
                TransferHelper.safeTransferETH(recipient, amount);
            } else {
                amount = IERC20(tokens[index]).balanceOf(address(this));
                TransferHelper.safeTransferWithoutRequire(tokens[index], recipient, amount);
            }
            emit Withdraw(tokens[index], msg.sender, recipient, amount);
        }
    }
}