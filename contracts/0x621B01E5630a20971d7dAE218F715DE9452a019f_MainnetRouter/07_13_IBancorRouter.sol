// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IBancorRouter {
    function tradeBySourceAmount(
        address sourceToken,
        address targetToken,
        uint256 sourceAmount,
        uint256 minReturnAmount,
        uint256 deadline,
        address receipient
    ) external payable returns (uint256 targetAmount);
}