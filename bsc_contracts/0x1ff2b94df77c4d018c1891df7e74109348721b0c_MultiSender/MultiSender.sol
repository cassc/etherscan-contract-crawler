/**
 *Submitted for verification at BscScan.com on 2023-02-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

contract MultiSender {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }


    function withdrawToken(address token, uint256 amount) public {
        require(msg.sender == _owner, "MultiSender: only owner can call this function");

        IBEP20 tokenContract = IBEP20(token);

        require(tokenContract.transfer(msg.sender, amount * (10**uint256(tokenContract.decimals()))), "MultiSender: token transfer failed");
    }

    function multiSendBNB(address[] memory recipients, uint256[] memory amounts) public payable {
        require(msg.sender == _owner, "MultiSender: only owner can call this function");
        require(recipients.length == amounts.length, "MultiSender: recipients and amounts array must have the same length");

        uint256 totalAmount = msg.value;
        for (uint256 i = 0; i < recipients.length; i++) {
            require(payable(recipients[i]).send(amounts[i]), "MultiSender: BNB transfer failed");
            totalAmount -= amounts[i];
        }
        // Send back any remaining balance to the sender
        if (totalAmount > 0) {
            payable(msg.sender).transfer(totalAmount);
        }
    }

   function multiSend(address token, address[] memory recipients, uint256[] memory amounts) public {
        require(msg.sender == _owner, "MultiSendToken: only owner can call this function");
        require(recipients.length == amounts.length, "MultiSendToken: recipients and amounts array must have the same length");

        IBEP20 tokenContract = IBEP20(token);

        for (uint256 i = 0; i < recipients.length; i++) {
            require(tokenContract.transfer(recipients[i], amounts[i] * (uint256(tokenContract.decimals()))), "MultiSendToken: token transfer failed");
        }
    }
}