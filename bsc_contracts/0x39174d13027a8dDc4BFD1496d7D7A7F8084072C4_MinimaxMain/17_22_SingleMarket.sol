// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./ArrayHelper.sol";
import "./Hints.sol";
import "./Dictionary.sol";
import "../v2/IToken.sol";

interface IRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract SingleMarket is OwnableUpgradeable {
    using ArrayHelper for uint[];
    using SafeERC20Upgradeable for IToken;

    using Dictionary for Dictionary.Entry[];

    address[] public relayTokens;
    IRouter[] public defaultRouters;
    uint public estimateMaxDepth = 1;

    constructor() initializer {
        __Ownable_init();
    }

    function getRelayTokens() external view returns (address[] memory) {
        return relayTokens;
    }

    function setRelayTokens(address[] calldata _relayTokens) external onlyOwner {
        relayTokens = _relayTokens;
    }

    function getRouters() external view returns (IRouter[] memory) {
        return defaultRouters;
    }

    function setRouters(IRouter[] calldata _routers) external onlyOwner {
        defaultRouters = _routers;
    }

    function setEstimateMaxDepth(uint _estimateMaxDepth) external onlyOwner {
        estimateMaxDepth = _estimateMaxDepth;
    }

    function swap(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address destination,
        bytes memory hints
    ) external returns (uint) {
        IToken(tokenIn).safeTransferFrom(address(msg.sender), address(this), amountIn);
        if (tokenIn == tokenOut) {
            require(amountIn >= amountOutMin, "amountOutMin");
            IToken(tokenIn).safeTransfer(destination, amountIn);
            return amountIn;
        }

        address lastToken = tokenIn;
        uint lastAmount = amountIn;
        for (uint i = 0; i <= estimateMaxDepth; i++) {
            address relay = Hints.getRelay(hints, lastToken, tokenOut);
            if (relay == address(0)) {
                address router = Hints.getRouter(hints, lastToken, tokenOut);
                return _swapDirect(router, lastToken, tokenOut, lastAmount, amountOutMin, destination);
            } else {
                address router = Hints.getRouter(hints, lastToken, relay);
                lastAmount = _swapDirect(router, lastToken, relay, lastAmount, 0, address(this));
                lastToken = relay;
            }
        }

        revert("no swap");
    }

    function _swapDirect(
        address router,
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address destination
    ) private returns (uint) {
        IToken(tokenIn).safeApprove(router, amountIn);
        return
            IRouter(router)
                .swapExactTokensForTokens({
                    amountIn: amountIn,
                    amountOutMin: amountOutMin,
                    path: ArrayHelper.new2(tokenIn, tokenOut),
                    to: destination,
                    deadline: block.timestamp
                })
                .last();
    }

    function estimateOut(
        IRouter[] memory routers,
        address tokenIn,
        address tokenOut,
        uint amountIn
    ) external view returns (uint amountOut, bytes memory hints) {
        if (routers.length == 0) {
            routers = defaultRouters;
        }

        if (tokenIn == tokenOut) {
            return (amountIn, Hints.empty());
        }

        (, amountOut, hints) = _estimateOutRecursive(
            routers,
            tokenIn,
            tokenOut,
            amountIn,
            Dictionary.fromKeys(relayTokens),
            estimateMaxDepth
        );
        require(amountOut > 0, "no estimation");
    }

    struct RecursiveState {
        uint amount1;
        bytes hints1;
        uint amount2;
        bytes hints2;
    }

    function _estimateOutRecursive(
        IRouter[] memory routers,
        address tokenIn,
        address tokenOut,
        uint amountIn,
        Dictionary.Entry[] memory discovered,
        uint depth
    )
        private
        view
        returns (
            Dictionary.Entry[] memory,
            uint amountOut,
            bytes memory hints
        )
    {
        RecursiveState memory state;

        (amountOut, hints) = _estimateOutDirect(routers, tokenIn, tokenOut, amountIn);

        if (depth == 0) {
            return (discovered, amountOut, hints);
        }

        for (uint i = 0; i < relayTokens.length; i++) {
            address relayToken = relayTokens[i];
            if (relayToken == tokenIn || relayToken == tokenOut) {
                continue;
            }

            (state.amount1, state.hints1) = _estimateOutDirect(routers, tokenIn, relayToken, amountIn);

            uint discoveredRelayAmount = discovered.get(relayToken);
            if (state.amount1 < discoveredRelayAmount) {
                continue;
            }
            discovered = discovered.set(relayToken, state.amount1);

            (discovered, state.amount2, state.hints2) = _estimateOutRecursive(
                routers,
                relayToken,
                tokenOut,
                state.amount1,
                discovered,
                depth - 1
            );

            if (state.amount2 > amountOut) {
                amountOut = state.amount2;
                hints = Hints.setRelay(tokenIn, tokenOut, relayToken);
                hints = Hints.merge2(hints, state.hints1);
                hints = Hints.merge2(hints, state.hints2);
            }
        }

        return (discovered, amountOut, hints);
    }

    function estimateOutWithHints(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        bytes memory hints
    ) external view returns (uint amountOut) {
        if (tokenIn == tokenOut) {
            return amountIn;
        }

        address lastToken = tokenIn;
        uint lastAmount = amountIn;
        for (uint i = 0; i <= estimateMaxDepth; i++) {
            address relay = Hints.getRelay(hints, lastToken, tokenOut);
            if (relay == address(0)) {
                address router = Hints.getRouter(hints, lastToken, tokenOut);
                return _getAmountOut2(IRouter(router), lastToken, tokenOut, lastAmount);
            } else {
                address router = Hints.getRouter(hints, lastToken, relay);
                lastAmount = _getAmountOut2(IRouter(router), lastToken, relay, lastAmount);
                lastToken = relay;
            }
        }

        return 0;
    }

    function _estimateOutDirect(
        IRouter[] memory routers,
        address tokenIn,
        address tokenOut,
        uint amountIn
    ) private view returns (uint amountOut, bytes memory hints) {
        IRouter router;
        (router, amountOut) = _optimalAmount(routers, tokenIn, tokenOut, amountIn);
        hints = Hints.setRouter(tokenIn, tokenOut, address(router));
    }

    function _optimalAmount(
        IRouter[] memory routers,
        address tokenIn,
        address tokenOut,
        uint amountIn
    ) private view returns (IRouter optimalRouter, uint optimalOut) {
        for (uint32 i = 0; i < routers.length; i++) {
            IRouter router = routers[i];
            uint amountOut = _getAmountOut2(router, tokenIn, tokenOut, amountIn);
            if (amountOut > optimalOut) {
                optimalRouter = routers[i];
                optimalOut = amountOut;
            }
        }
    }

    function _getAmountOut2(
        IRouter router,
        address tokenIn,
        address tokenOut,
        uint amountIn
    ) private view returns (uint) {
        return _getAmountSafe(router, ArrayHelper.new2(tokenIn, tokenOut), amountIn);
    }

    function _getAmountOut3(
        IRouter router,
        address tokenIn,
        address tokenMid,
        address tokenOut,
        uint amountIn
    ) private view returns (uint) {
        return _getAmountSafe(router, ArrayHelper.new3(tokenIn, tokenMid, tokenOut), amountIn);
    }

    function _getAmountSafe(
        IRouter router,
        address[] memory path,
        uint amountIn
    ) public view returns (uint output) {
        bytes memory payload = abi.encodeWithSelector(router.getAmountsOut.selector, amountIn, path);
        (bool success, bytes memory response) = address(router).staticcall(payload);
        if (success && response.length > 32) {
            return ArrayHelper.lastUint(response);
        }
        return 0;
    }

    function destroy() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}