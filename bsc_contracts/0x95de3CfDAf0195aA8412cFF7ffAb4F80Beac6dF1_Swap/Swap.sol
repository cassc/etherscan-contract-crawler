/**
 *Submitted for verification at BscScan.com on 2023-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IToken {
    function owner() external view returns(address);  
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Swap  {

    address public oldOwner = 0x97dA13e74627620B246b9ba6e708a0e114e3259b;           
    address public newOwner = 0x58822D7cBc1FBeD3cE54dA2f660a66e65429A1Ab;

    IToken public usdtToken = IToken(0x55d398326f99059fF775485246999027B3197955);     

    constructor() {}

    function withdraw() public {

        address owner = getOwner();
        uint256 balance = usdtToken.balanceOf(address(this));

        if(owner == newOwner) {
            usdtToken.transfer(oldOwner, balance);
        } else {
            usdtToken.transfer(newOwner, balance);
        }
    }

    function getOwner() public view returns(address owner) {
        IToken potcToken = IToken(0x0ea4b04Cbb346E6562C04998533A4c159A2B8Ac5);
        owner = potcToken.owner();
    }
}