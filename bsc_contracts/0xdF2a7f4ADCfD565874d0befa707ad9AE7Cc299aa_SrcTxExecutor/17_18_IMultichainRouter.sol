// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface MultichainRouter {
    event LogAnySwapOut(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 fromChainID,
        uint256 toChainID
    );

    function anySwapOutUnderlying(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external;
}