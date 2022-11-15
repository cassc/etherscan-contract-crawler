//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockRouter {
    address public _ellipsisDstToken;

    constructor(address ellipsisDstToken) {
        _ellipsisDstToken = ellipsisDstToken;
    }

    // uniswap
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        amounts[1] = 10 ether;
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[1]).transfer(to, amounts[1]);

        return amounts;
    }

    // ellipsis
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external {
        IERC20(_ellipsisDstToken).transfer(msg.sender, IERC20(_ellipsisDstToken).balanceOf(address(this)));
    }
}