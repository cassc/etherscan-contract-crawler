/**
 *Submitted for verification at BscScan.com on 2023-04-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256 amount) external;
}

contract BulkTransferWBNB {
    address private _owner;
    IWBNB private _wbnb;
    
    constructor(address wbnb) {
        _owner = msg.sender;
        _wbnb = IWBNB(wbnb);
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }
    
    function bulkTransfer(address[] memory recipients, uint256 amount) public payable onlyOwner {
        uint256 totalAmount = amount * recipients.length;
        require(msg.value >= totalAmount, "Insufficient WBNB");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            _wbnb.transfer(recipients[i], amount);
        }
        
        if (msg.value > totalAmount) {
            uint256 refundAmount = msg.value - totalAmount;
            _wbnb.withdraw(refundAmount);
            payable(msg.sender).transfer(refundAmount);
        }
    }
    
    receive() external payable {
        require(msg.sender == address(_wbnb), "WBNB only");
    }
}