// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITraderJoeV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMinAVAX,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);
}