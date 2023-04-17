/**
 *Submitted for verification at BscScan.com on 2023-04-16
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IGenericLPPair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function sync() external;
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
        require(inputToken.transferFrom(msg.sender, address(this), amountIn), "TransferFrom failed.");

        // Approve the LP pair contract to spend the input tokens.
        inputToken.approve(lpPairAddress, amountIn);

        // Transfer input tokens to the LP pair contract.
        require(inputToken.transfer(lpPairAddress, amountIn), "Transfer to LP pair failed.");

        // Synchronize the LP pair contract (if available).
        IGenericLPPair(lpPairAddress).sync();

        // Call the swap function on the LP pair contract.
        IGenericLPPair(lpPairAddress).swap(amount0Out, amount1Out, to, "");
    }
    
    // Function to receive BNB
    receive() external payable {}

    // Function to withdraw BNB
    function withdrawBNB(uint256 amount) external {
        require(amount <= address(this).balance, "Insufficient BNB balance.");
        payable(msg.sender).transfer(amount);
    }

    // Function to withdraw ERC20 tokens
    function withdrawERC20(address tokenAddress, uint256 amount) external {
        IERC20 token = IERC20(tokenAddress);
        require(address(token) != address(0), "Invalid token address");
        token.transfer(msg.sender, amount);
    }
}