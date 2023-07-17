/**
 *Submitted for verification at Etherscan.io on 2023-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Abstract
interface USDC {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// Contract
contract UsdcDemo{

    USDC public USDc;

    // Contract Owner
    address payable public owner; 

    constructor(address usdcContractAddress) {

        USDc = USDC(usdcContractAddress);

        // User who is calling this function address
        owner = payable(msg.sender);
    }


    function Fund(uint $USDC) public payable {

        // Transfer USDC to this contract from the sender account
        USDc.transferFrom(msg.sender, address(this), $USDC * 10 ** 6);  


        // Transfer to the owner
        USDc.transfer(owner, $USDC * 10 ** 6);  
    }

    // Alternatively
    receive() payable external {

    //Send the fund to the owner of the contract.
       owner.transfer(address(this).balance);
    }      
}