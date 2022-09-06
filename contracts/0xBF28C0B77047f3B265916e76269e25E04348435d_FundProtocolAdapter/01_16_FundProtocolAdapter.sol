// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IFundManager} from "../interfaces/fund/IFundManager.sol";
import {IFundAccount} from "../interfaces/fund/IFundAccount.sol";
import {INonfungiblePositionManager} from "../intergrations/uniswap/INonfungiblePositionManager.sol";
import {BytesLib} from "../intergrations/uniswap/BytesLib.sol";
import {Path} from "../libraries/Path.sol";

// PA0 - Invalid account owner
// PA1 - Invalid protocol
// PA2 - Invalid selector
// PA3 - Invalid multicall
// PA4 - Invalid token
// PA5 - Invalid recipient
// PA6 - Invalid v2 path

struct ExactSwapParams {
    bytes path;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
}

contract FundProtocolAdapter is ReentrancyGuard {
    using BytesLib for bytes;
    using Path for bytes;

    IFundManager public fundManager;

    address public weth9;
    address public constant swapRouter = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address public constant posManager = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    // Contract version
    uint256 public constant version = 1;
    
    constructor(address _fundManager) {
        fundManager = IFundManager(_fundManager);
        weth9 = fundManager.weth9();
    }

    function executeOrder(
        address account,
        address target,
        bytes memory data,
        uint256 value
    ) external nonReentrant returns (bytes memory result) {
        IFundAccount fundAccount = IFundAccount(account);
        if (fundAccount.closed() == 0) {
            // only account GP can call
            require(msg.sender == fundAccount.gp(), "PA0");
            (bytes4 selector, bytes memory params) = _decodeCalldata(data);
            if (selector == 0x095ea7b3) {
                // erc20 approve
                require(fundAccount.isTokenAllowed(target), "PA4");
                (address spender, uint256 amount) = abi.decode(params, (address, uint256));
                require(fundAccount.isProtocolAllowed(spender), "PA1");
                fundManager.provideAccountAllowance(account, target, spender, amount);
            } else {
                // execute first to analyse result
                result = fundManager.executeOrder(account, target, data, value);
                if (target == weth9) {
                    // weth9 deposit/withdraw
                    require(selector == 0xd0e30db0 || selector == 0x2e1a7d4d, "PA2");
                } else {
                    // defi protocols
                    require(fundAccount.isProtocolAllowed(target), "PA1");
                    if (target == swapRouter) {
                        _analyseSwapCalls(account, selector, params, value);
                    } else if (target == posManager) {
                        _analyseLpCalls(account, selector, params, result);
                    }
                }
            }
        } else {
            // open all access to manager owner
            require(msg.sender == fundManager.owner(), "PA0");
            result = fundManager.executeOrder(account, target, data, value);
        }
    }

    function _tokenAllowed(address account, address token) private view returns (bool) {
        return IFundAccount(account).isTokenAllowed(token);
    }

    function _decodeCalldata(bytes memory data) private pure returns (bytes4 selector, bytes memory params) {
        assembly {
            selector := mload(add(data, 32))
        }
        params = data.slice(4, data.length - 4);
    }

    function _isMultiCall(bytes4 selector) private pure returns (bool) {
        return selector == 0xac9650d8 || selector == 0x5ae401dc || selector == 0x1f0464d1;
    }

    function _decodeMultiCall(bytes4 selector, bytes memory params) private pure returns (bytes4[] memory selectorArr, bytes[] memory paramsArr) {
        bytes[] memory arr;
        if (selector == 0xac9650d8) {
            // multicall(bytes[])
            (arr) = abi.decode(params, (bytes[]));
        } else if (selector == 0x5ae401dc) {
            // multicall(uint256,bytes[])
            (, arr) = abi.decode(params, (uint256, bytes[]));
        } else if (selector == 0x1f0464d1) {
            // multicall(bytes32,bytes[])
            (, arr) = abi.decode(params, (bytes32, bytes[]));
        }
        selectorArr = new bytes4[](arr.length);
        paramsArr = new bytes[](arr.length);
        for (uint256 i = 0; i < arr.length; i++) {
            (selectorArr[i], paramsArr[i]) = _decodeCalldata(arr[i]);
        }
    }

    function _analyseSwapCalls(address account, bytes4 selector, bytes memory params, uint256 value) private view {
        bool isTokenInETH;
        bool isTokenOutETH;
        if (_isMultiCall(selector)) {
            (bytes4[] memory selectorArr, bytes[] memory paramsArr) = _decodeMultiCall(selector, params);
            for (uint256 i = 0; i < selectorArr.length; i++) {
                (isTokenInETH, isTokenOutETH) = _checkSingleSwapCall(account, selectorArr[i], paramsArr[i], value);
                // if swap native ETH, must check multicall
                if (isTokenInETH) {
                    // must call refundETH last
                    require(selectorArr[selectorArr.length - 1] == 0x12210e8a, "PA3");
                }
                if (isTokenOutETH) {
                    // must call unwrapWETH9 last
                    require(selectorArr[selectorArr.length - 1] == 0x49404b7c, "PA3");
                }
            }
        } else {
            (isTokenInETH, isTokenOutETH) = _checkSingleSwapCall(account, selector, params, value);
            require(!isTokenInETH && !isTokenOutETH, "PA2");
        }
    }

    function _checkSingleSwapCall(
        address account,
        bytes4 selector,
        bytes memory params,
        uint256 value
    ) private view returns (bool isTokenInETH, bool isTokenOutETH) {
        address tokenIn;
        address tokenOut;
        address recipient;
        if (selector == 0x04e45aaf || selector == 0x5023b4df) {
            // exactInputSingle/exactOutputSingle
            (tokenIn,tokenOut, ,recipient, , , ) = abi.decode(params, (address,address,uint24,address,uint256,uint256,uint160));
            isTokenInETH = (tokenIn == weth9 && value > 0 && selector == 0x5023b4df);
            isTokenOutETH = (tokenOut == weth9 && recipient == address(2));
            require(recipient == account || isTokenOutETH, "PA5");
            require(_tokenAllowed(account, tokenIn), "PA4");
            require(_tokenAllowed(account, tokenOut), "PA4");
        } else if (selector == 0xb858183f || selector == 0x09b81346) {
            // exactInput/exactOutput
            ExactSwapParams memory swap = abi.decode(params, (ExactSwapParams));
            (tokenIn,tokenOut) = swap.path.decode();
            isTokenInETH = (tokenIn == weth9 && value > 0 && selector == 0x09b81346);
            isTokenOutETH = (tokenOut == weth9 && swap.recipient == address(2));
            require(swap.recipient == account || isTokenOutETH, "PA5");
            require(_tokenAllowed(account, tokenIn), "PA4");
            require(_tokenAllowed(account, tokenOut), "PA4");
        } else if (selector == 0x472b43f3 || selector == 0x42712a67) {
            // swapExactTokensForTokens/swapTokensForExactTokens
            (,,address[] memory path,address to) = abi.decode(params, (uint256,uint256,address[],address));
            require(path.length >= 2, "PA6");
            tokenIn = path[0];
            tokenOut = path[path.length - 1];
            isTokenInETH = (tokenIn == weth9 && value > 0 && selector == 0x42712a67);
            isTokenOutETH = (tokenOut == weth9 && to == address(2));
            require(to == account || isTokenOutETH, "PA5");
            require(_tokenAllowed(account, tokenIn), "PA4");
            require(_tokenAllowed(account, tokenOut), "PA4");
        } else if (selector == 0x49404b7c) {
            // unwrapWETH9
            ( ,recipient) = abi.decode(params, (uint256,address));
            require(recipient == account, "PA5");
        } else if (selector == 0x12210e8a) {
            // refundETH
        } else {
            revert("PA2");
        }
    }

    function _analyseLpCalls(
        address account,
        bytes4 selector,
        bytes memory params,
        bytes memory result
    ) private {
        bool isCollectETH;
        address sweepToken;
        if (_isMultiCall(selector)) {
            (bytes4[] memory selectorArr, bytes[] memory paramsArr) = _decodeMultiCall(selector, params);
            (bytes[] memory resultArr) = abi.decode(result, (bytes[]));
            for (uint256 i = 0; i < selectorArr.length; i++) {
                (isCollectETH, sweepToken) = _checkSingleLpCall(account, selectorArr[i], paramsArr[i], resultArr[i]);
                // if collect native ETH, must check multicall
                if (isCollectETH) {
                    // must call unwrapWETH9 & sweepToken after
                    require(selectorArr[i+1] == 0x49404b7c, "PA3");
                    require(selectorArr[i+2] == 0xdf2ab5bb, "PA3");
                    (address token, , ) = abi.decode(paramsArr[i+2], (address,uint256,address));
                    // sweepToken must be another collect token
                    require(sweepToken == token, "PA3");
                }
            }
        } else {
            (isCollectETH, ) = _checkSingleLpCall(account, selector, params, result);
            require(!isCollectETH, "PA2");
        }
    }

    function _checkSingleLpCall(
        address account,
        bytes4 selector,
        bytes memory params,
        bytes memory result
    ) private returns (
        bool isCollectETH,
        address sweepToken
    ) {
        address token0;
        address token1;
        address recipient;
        uint256 tokenId;
        if (selector == 0x13ead562) {
            // createAndInitializePoolIfNecessary
            (token0,token1, , ) = abi.decode(params, (address,address,uint24,uint160));
            require(_tokenAllowed(account, token0), "PA4");
            require(_tokenAllowed(account, token1), "PA4");
        } else if (selector == 0x88316456) {
            // mint
            (token0,token1, , , , , , , ,recipient, ) = abi.decode(params, (address,address,uint24,int24,int24,uint256,uint256,uint256,uint256,address,uint256));
            require(recipient == account, "PA5");
            require(_tokenAllowed(account, token0), "PA4");
            require(_tokenAllowed(account, token1), "PA4");
            (tokenId, , , ) = abi.decode(result, (uint256,uint128,uint256,uint256));
            fundManager.onMint(account, tokenId);
        } else if (selector == 0x219f5d17) {
            // increaseLiquidity
            (tokenId, , , , , ) = abi.decode(params, (uint256,uint256,uint256,uint256,uint256,uint256));
            fundManager.onIncrease(account, tokenId);
        } else if (selector == 0x0c49ccbe) {
            // decreaseLiquidity
        } else if (selector == 0xfc6f7865) {
            // collect
            (tokenId,recipient, , ) = abi.decode(params, (uint256,address,uint128,uint128));
            if (recipient == address(0)) {
                // collect native ETH
                // check if position include weth9, note another token for sweep
                ( , , token0, token1, , , , , , , , ) = INonfungiblePositionManager(posManager).positions(tokenId);
                if (token0 == weth9) {
                    isCollectETH = true;
                    sweepToken = token1;
                } else if (token1 == weth9) {
                    isCollectETH = true;
                    sweepToken = token0;
                }
            }
            require(recipient == account || isCollectETH, "PA5");
            fundManager.onCollect(account, tokenId);
        } else if (selector == 0x49404b7c) {
            // unwrapWETH9
            ( ,recipient) = abi.decode(params, (uint256,address));
            require(recipient == account, "PA5");
        } else if (selector == 0xdf2ab5bb) {
            // sweepToken
            (token0, ,recipient) = abi.decode(params, (address,uint256,address));
            require(recipient == account, "PA5");
            require(_tokenAllowed(account, token0), "PA4");
        } else if (selector == 0x12210e8a) {
            // refundETH
        } else {
            revert("PA2");
        }
    }

}