/**
 *Submitted for verification at Etherscan.io on 2023-05-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract Test {
    event TransferWithMessage(address indexed from, address indexed to, uint256 amount, string message);

    function transferWithMessage(address tokenAddress, address recipient, uint256 amount, string memory message) external {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(recipient, amount);
        emit TransferWithMessage(msg.sender, recipient, amount, message);
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}