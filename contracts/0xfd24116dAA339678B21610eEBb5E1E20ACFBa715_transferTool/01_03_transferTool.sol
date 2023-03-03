// SPDX-License-Identifier: GPL-3.0
//bsc_test地址0x53aCB70702495C957C741ccfCC79eB4D8F79B548
pragma solidity ^0.8;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract transferTool{
    function transferEth(address[] calldata tos,uint[] calldata amounts) public payable{
        require(tos.length == amounts.length,"wrong amount");
        uint total_amount = 0;
        for(uint i=0;i<tos.length;i++){
            payable(tos[i]).transfer(amounts[i]);
            total_amount += amounts[i];
        }
        require(total_amount == msg.value,"wrong total amount");
    }
    function transferErc20(address tokenAddress,address[] calldata tos,uint[] calldata amounts) public{
        require(tos.length == amounts.length,"wrong amount");
        for(uint i=0;i<tos.length;i++){
            IERC20Metadata token = IERC20Metadata(tokenAddress);
            token.transferFrom(msg.sender,tos[i],amounts[i]);
        }
    }

}