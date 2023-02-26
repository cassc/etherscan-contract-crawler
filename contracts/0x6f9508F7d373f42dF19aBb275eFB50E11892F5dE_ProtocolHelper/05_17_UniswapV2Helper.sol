// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "../interfaces/UniswapV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title HashflowHelper
 * @notice Helper that performs onchain calculation required to call a Uniswap V2 contract and returns corresponding caller and data
 */
abstract contract UniswapV2Helper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function swapUniswapV2(
        uint256 amountSpecified,
        IUniswapV2Pair pair,
        address recipient,
        IERC20 sourceToken,
        IERC20 targetToken
    ) external view returns (address target, address sourceTokenInteractionTarget, uint256 valueLimit, bytes memory data) {
        (uint256 result0, uint256 result1) = _calcInOutAmounts(
            pair,
            sourceToken,
            targetToken,
            amountSpecified
        );
        bytes memory resultData = abi.encodeCall(pair.swap, (result0, result1, recipient, ""));
        return (address(pair), address(pair), amountSpecified, resultData);
    }

    function _calcInOutAmounts(
        IUniswapV2Pair pair,
        IERC20 sourceToken,
        IERC20 targetToken,
        uint256 amountIn
    ) private view returns (uint256 result0, uint256 result1) {
        (uint256 reserveIn, uint256 reserveOut, ) = pair.getReserves();
        if (sourceToken > targetToken) {
            (reserveIn, reserveOut) = (reserveOut, reserveIn);
        }
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        unchecked {
            uint256 amountOut = numerator / denominator;

            return
                address(sourceToken) < address(targetToken)
                    ? (uint256(0), amountOut)
                    : (amountOut, uint256(0));
        }
    }
}