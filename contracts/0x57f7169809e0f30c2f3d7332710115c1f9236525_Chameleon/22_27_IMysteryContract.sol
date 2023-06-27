// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IMysteryContract {
    function handleBuy(address account, uint256 amount, int256 feeTokens) external;
    function handleSell(address account, uint256 amount, int256 feeTokens) external;
}