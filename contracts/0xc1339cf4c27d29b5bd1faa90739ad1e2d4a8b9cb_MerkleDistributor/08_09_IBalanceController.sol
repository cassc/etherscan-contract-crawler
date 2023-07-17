// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IBalanceController {
    receive() external payable;

    // withdrawToken allows the owner to move any tokens owned by the contract.
    function withdrawToken(address token, address account, uint256 amount) external;

    // withdrawEth allows the owner to move any coins held by the contract.
    function withdrawEth(address account, uint256 amount) external;
}