// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/common/IUniswapRouterETH.sol";

library SafeUniswapRouter {

    using SafeMath for uint256;

    function safeSwapExactTokensForTokens(
        IUniswapRouterETH _used,
        uint[2] memory _slippage,
        uint _amountIn,
        address[] memory _path,
        address _to,
        uint deadline
    ) internal {

        uint indexAmountOut = _path.length - 1;

        uint[] memory amountsOutExpected = _used.getAmountsOut(_amountIn, _path);

        uint256 minMintAmount = amountsOutExpected[indexAmountOut].mul(_slippage[0]).div(_slippage[1]);

        uint[] memory amountsOutObtained = _used.swapExactTokensForTokens(_amountIn, minMintAmount, _path, _to, deadline);

        require(amountsOutObtained[indexAmountOut] >= minMintAmount, "amountsOutObtained[indexAmountOut]<minMintAmount");
    }
}