/**
 *Submitted for verification at Etherscan.io on 2023-07-06
*/

// SPDX-License-Identifier: MIT
/**


_______/]_________[\___
|    ____     ___|---------------|=====
|_ /      /  /_|   |
         /_/     \_ \


https://eth-og.net/
https://t.me/ogerc20
https://twitter.com/originalgerc20

**/
pragma solidity 0.8.19;

contract OG {
    function name() public pure returns (string memory) {return "OriginalGangster";}
    function symbol() public pure returns (string memory) {return "OG";}
    function decimals() public pure returns (uint8) {return 0;}
    function totalSupply() public pure returns (uint256) {return 100000000;}
    function balanceOf(address account) public view returns (uint256) {return 0;}
    function transfer(address recipient, uint256 amount) public returns (bool) {return true;}
    function allowance(address owner, address spender) public view  returns (uint256) {return 0;}
    function approve(address spender, uint256 amount) public  returns (bool) {return true;}
    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool) {return true;}
    receive() external payable {}
}