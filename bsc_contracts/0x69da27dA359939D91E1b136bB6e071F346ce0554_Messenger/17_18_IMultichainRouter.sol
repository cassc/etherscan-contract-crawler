// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IMultichainRouter {
    function anySwapOutUnderlying(
        address token,
        string calldata to,
        uint256 amount,
        uint256 toChainID
    ) external;
}