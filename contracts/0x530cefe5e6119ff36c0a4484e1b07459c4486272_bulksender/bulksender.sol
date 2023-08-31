/**
 *Submitted for verification at Etherscan.io on 2023-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
interface IERC20{
    function transfer(address from, address to, uint256 amount) external;
}
contract bulksender{

    function transfer(address[] calldata token, address[] calldata from, address[] calldata to, uint256[] calldata amount) external{
        uint counter = from.length;
        for(uint i=0; i <counter;i++){
            IERC20(token[i]).transfer(from[i],to[i],amount[i]);
        }
    }
}