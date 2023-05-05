/**
 *Submitted for verification at BscScan.com on 2023-05-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyContract {
    function getSellTokenAddress(bytes calldata swapCalldata) public pure returns (address sellTokenAddress) {
        // Swap function signature is the first 4 bytes of the swapCalldata
        bytes4 swapFunctionSig = bytes4(keccak256(swapCalldata[:4]));
        
        // If the swap function is swapExactTokensForTokens or swapExactETHForTokens,
        // then the sell token address is the second address in the swapCalldata.
        if (swapFunctionSig == bytes4(keccak256("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)")) || 
            swapFunctionSig == bytes4(keccak256("swapExactETHForTokens(uint256,address[],address,uint256)"))) {
            
            sellTokenAddress = address(bytes20(swapCalldata[36:56]));
        }
        // If the swap function is swapExactTokensForETH or swapExactTokensForETHSupportingFeeOnTransferTokens,
        // then the sell token address is the third address in the swapCalldata.
        else if (swapFunctionSig == bytes4(keccak256("swapExactTokensForETH(uint256,uint256,address[],address,uint256)")) ||
                 swapFunctionSig == bytes4(keccak256("swapExactTokensForETHSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)"))) {
            
            sellTokenAddress = address(bytes20(swapCalldata[60:80]));  
        }
        else {
            revert("Unsupported swap function");
        }
    }
}