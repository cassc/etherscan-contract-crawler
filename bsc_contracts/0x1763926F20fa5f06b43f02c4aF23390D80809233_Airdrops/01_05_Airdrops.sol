// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20.sol";

contract Airdrops is Ownable {
    

    function makeTransfer(
        address payable[] memory addressArray,
        uint256[] memory amountArray,
        address tokenAddress
    ) external onlyOwner {
        require(
            addressArray.length <= 100,
            "Only 100 user allowed for airdrops"
        );
        require(
            addressArray.length == amountArray.length,
            "Arrays must be of same size."
        );
        IERC20  Token;
        Token = IERC20(tokenAddress);
        for (uint256 i = 0; i < addressArray.length; i++) {
           require(addressArray[i]!=address(0),"Zero address is not allowed");
           require(amountArray[i]>0,"Amount should be greater than zero");
            require(
                Token.allowance(msg.sender, address(this)) >= amountArray[i],
                "Insufficient allowance."
            );
            require(
                Token.balanceOf(msg.sender) >= amountArray[i],
                "you have insufficient token balance."
            );
            TransferHelper.safeTransferFrom(
                tokenAddress,
                msg.sender,
                addressArray[i],
                amountArray[i]
            );
        }
    }
}