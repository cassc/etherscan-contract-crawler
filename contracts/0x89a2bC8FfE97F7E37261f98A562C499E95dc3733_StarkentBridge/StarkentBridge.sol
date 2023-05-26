/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IStarknetBridge {
    function deposit(uint256 amount, uint256 starknetWallet) external payable;
}

contract StarkentBridge {
    IStarknetBridge public starknetBridge;
    address payable public owner;

    constructor(address _starknetBridgeAddress) {
        starknetBridge = IStarknetBridge(_starknetBridgeAddress);
        owner = payable(msg.sender);
    }

    function callDeposit(uint256 amount, uint256 starknetWallet) public payable {
        uint256 fee = 0.00005 ether;
        starknetBridge.deposit{value: msg.value - fee}(amount - fee - 1, starknetWallet);
        owner.transfer(fee-1);
    }
}