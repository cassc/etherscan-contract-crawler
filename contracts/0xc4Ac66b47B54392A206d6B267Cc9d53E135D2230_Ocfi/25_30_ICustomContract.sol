// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ICustomContract {
    function beforeTokenTransfer(address from, address to, uint256 amount) external;
    function handleBuy(address account, uint256 amount, uint256 feeTokens) external;
    function handleSell(address account, uint256 amount, uint256 feeTokens) external;
    function handleBalanceUpdated(address account, uint256 amount) external;

    function getData(address account) external view returns (uint256[] memory data);
}