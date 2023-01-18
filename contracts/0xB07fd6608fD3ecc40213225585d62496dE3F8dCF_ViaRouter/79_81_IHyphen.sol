// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IHyphen {
    function depositErc20(
        uint256 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        string memory tag
    ) external;

    function depositNative(
        address receiver,
        uint256 toChainId,
        string memory tag
    ) external;
}