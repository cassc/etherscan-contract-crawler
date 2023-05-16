// SPDX-License-Identifier: MIT

// solhint-disable-next-line
pragma solidity 0.8.2;

import "../security/Security.sol";
import "../utils/IPancakeRouter01.sol";

abstract contract AlternativeTokenHelper is Security {
    SwapRouter public swapRouter;

    event SetRouter(address indexed newSwapRouter);

    function setRouter(address router) onlyOwner external {
        swapRouter = SwapRouter(router);
        emit SetRouter(router);
    }

    function evaluateAlternativeAmount(uint mainAmount, address mainToken, address alternativeToken) internal view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = mainToken;
        path[1] = alternativeToken;
        return swapRouter.getAmountsOut(mainAmount, path)[0];
    }
}