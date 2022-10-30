//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

// needs to be implemented by contract doing flashswap
interface IPlaygroundCallee {
    function playgroundCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}