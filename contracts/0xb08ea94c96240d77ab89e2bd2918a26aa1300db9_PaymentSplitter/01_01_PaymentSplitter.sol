// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PaymentSplitter {
    address payable private constant wallet1 = payable(0x51aE040f59F2b8E5ea8bc84f8D282adB67571671);
    address payable private constant wallet2 = payable(0x1c14C2C2a61282432569F8Ed3BEd92b4905BcAC1);
    
    fallback() external payable { }

    receive() external payable { }

    function withdraw() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available");
        
        uint256 half = balance / 2;
        (bool success1, ) = wallet1.call{value: half}("");
        require(success1, "Transfer to wallet1 failed");
        
        (bool success2, ) = wallet2.call{value: half}("");
        require(success2, "Transfer to wallet2 failed");
    }
}