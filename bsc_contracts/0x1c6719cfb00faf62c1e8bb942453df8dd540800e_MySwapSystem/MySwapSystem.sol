/**
 *Submitted for verification at BscScan.com on 2023-05-14
*/

// File: contracts\DexIntegratePS.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPancakeRouter01 {
    function WETH() external pure returns (address);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

contract MySwapSystem {

    IPancakeRouter01 pancakeRouter;

    address owner;
    address feeRecipientAddress;
    uint256 feePercent;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(address _pancakeRouterAddress) {
        pancakeRouter = IPancakeRouter01(_pancakeRouterAddress);
        owner = msg.sender;
    }

    event SwapTransfer(address from, address to, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    function setFeeRecipient(address recipient) public onlyOwner {        feeRecipientAddress = recipient;
    }

    function viewFeeRecipient() public onlyOwner view returns (address) {
        return feeRecipientAddress;
    }

    function sendFeeToRecipient(uint256 amountFee) private {
        address payable account = payable(feeRecipientAddress);
        account.transfer(amountFee);
    }

    function swapBNBForExactTokens(uint valueBNB, uint amountOut, address[] memory path, address sender, uint valueFee) external payable {
        pancakeRouter.swapETHForExactTokens{value: valueBNB}(amountOut, path, sender, block.timestamp + 60*10);
        sendFeeToRecipient(valueFee);
        emit SwapTransfer(address(pancakeRouter), sender, path[0], path[1], valueBNB, amountOut);
    }

    function swapTokensForExactBNB(uint amountOut, uint amountIn, address[] memory path, address sender, uint valueFee) external {
        pancakeRouter.swapTokensForExactETH(amountOut, amountIn, path, sender, block.timestamp + 60*10);
        sendFeeToRecipient(valueFee);
        emit SwapTransfer(address(pancakeRouter), sender, path[0], path[1], amountIn, amountOut);
    }
}