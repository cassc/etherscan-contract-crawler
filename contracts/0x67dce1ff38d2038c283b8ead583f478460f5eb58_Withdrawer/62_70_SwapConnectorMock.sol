// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '@mimic-fi/v2-swap-connector/contracts/ISwapConnector.sol';
import '@mimic-fi/v2-registry/contracts/implementations/BaseImplementation.sol';

import '../samples/DexMock.sol';

contract SwapConnectorMock is ISwapConnector, BaseImplementation {
    bytes32 public constant override NAMESPACE = keccak256('SWAP_CONNECTOR');

    DexMock public immutable dex;

    constructor(address registry) BaseImplementation(registry) {
        dex = new DexMock();
    }

    function mockRate(uint256 newRate) external {
        dex.mockRate(newRate);
    }

    function swap(
        uint8, /* source */
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        bytes memory data
    ) external override returns (uint256 amountOut) {
        IERC20(tokenIn).approve(address(dex), amountIn);
        return dex.swap(tokenIn, tokenOut, amountIn, minAmountOut, data);
    }
}