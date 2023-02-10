// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IMessenger {
    function bridgeUSDL(
        uint256 chainId,
        address receiver,
        uint256 amount
    ) external payable;

    function bridgeCollateral(
        uint256 chainId,
        address collateral,
        uint256 amount
    ) external payable;
}