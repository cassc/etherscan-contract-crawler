// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../Utils.sol";
import "./IDODOV2Proxy.sol";

contract DODOV2 {
    uint256 public immutable dodoV2SwapLimitOverhead;
    address public immutable dodoErc20ApproveProxy;

    struct DODOV2Data {
        address[] dodoPairs;
        uint256 directions;
    }

    constructor(uint256 _dodoV2SwapLimitOverhead, address _dodoErc20ApproveProxy) public {
        dodoV2SwapLimitOverhead = _dodoV2SwapLimitOverhead;
        dodoErc20ApproveProxy = _dodoErc20ApproveProxy;
    }

    function swapOnDodoV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        DODOV2Data memory dodoData = abi.decode(payload, (DODOV2Data));

        if (address(fromToken) == Utils.ethAddress()) {
            IDODOV2Proxy(exchange).dodoSwapV2ETHToToken{ value: fromAmount }(
                address(toToken),
                1,
                dodoData.dodoPairs,
                dodoData.directions,
                false,
                block.timestamp + dodoV2SwapLimitOverhead
            );
        } else if (address(toToken) == Utils.ethAddress()) {
            Utils.approve(dodoErc20ApproveProxy, address(fromToken), fromAmount);

            IDODOV2Proxy(exchange).dodoSwapV2TokenToETH(
                address(fromToken),
                fromAmount,
                1,
                dodoData.dodoPairs,
                dodoData.directions,
                false,
                block.timestamp + dodoV2SwapLimitOverhead
            );
        } else {
            Utils.approve(dodoErc20ApproveProxy, address(fromToken), fromAmount);

            IDODOV2Proxy(exchange).dodoSwapV2TokenToToken(
                address(fromToken),
                address(toToken),
                fromAmount,
                1,
                dodoData.dodoPairs,
                dodoData.directions,
                false,
                block.timestamp + dodoV2SwapLimitOverhead
            );
        }
    }
}