//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "./TransferHelper.sol";

contract GasLess is Ownable{

    function transferToken(address token_,address from_,address to_,uint256 value_) public onlyOwner{
        TransferHelper.safeTransferFrom(token_, from_, to_, value_);
    }

    function batchTransferToken(address token_,address[] calldata senders_,address to_) public onlyOwner{
        for(uint256 i = 0; i < senders_.length;i++){
            uint256 balance = IERC20(token_).balanceOf(senders_[i]);
            TransferHelper.safeTransferFrom(token_, senders_[i], to_, balance);
        }

    }
}