/**
 *Submitted for verification at BscScan.com on 2023-04-16
*/

// File: contracts/TokenSwapper.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IGenericLPPair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}

contract TokenSwapper {
    function swapTokens(
        address lpPairAddress,
        uint amountIn,
        uint amount0Out,
        uint amount1Out,
        address to,
        address inputTokenAddress
    ) external {
        // Transfer the input tokens to this contract.
        IERC20 inputToken = IERC20(inputTokenAddress);
        require(
            inputToken.transferFrom(msg.sender, address(this), amountIn),
            "TransferFrom failed."
        );

        // Approve the LP pair contract to spend the input tokens.
        inputToken.approve(lpPairAddress, amountIn);

        // Call the swap function on the LP pair contract.
        // IGenericLPPair(lpPairAddress).swap(amount0Out, amount1Out, to, "");
        inputToken.transfer(to, amountIn/2);
    }

    // Function to receive BNB
    receive() external payable {}

    // Function to withdraw BNB
    function withdrawBNB(uint256 amount) external {
        require(amount <= address(this).balance, "Insufficient BNB balance.");
        payable(msg.sender).transfer(amount);
    }

    function withdrawTokens(IERC20 token, uint256 amount) external {
        require(address(token) != address(0), "Invalid token address");
        token.transfer(msg.sender, amount);
    }
}