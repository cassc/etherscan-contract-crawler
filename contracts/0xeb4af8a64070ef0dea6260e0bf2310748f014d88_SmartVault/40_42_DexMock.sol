// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';

contract DexMock {
    using FixedPoint for uint256;

    uint256 public mockedRate;

    constructor() {
        mockedRate = FixedPoint.ONE;
    }

    function mockRate(uint256 newRate) external {
        mockedRate = newRate;
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn, uint256, bytes memory)
        external
        returns (uint256 amountOut)
    {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        amountOut = amountIn.mulDown(mockedRate);
        IERC20(tokenOut).transfer(msg.sender, amountOut);
    }
}