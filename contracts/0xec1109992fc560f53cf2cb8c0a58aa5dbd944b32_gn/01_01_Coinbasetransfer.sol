// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

contract gn {
    address private owner;  
    event MevBot(address from, address miner, uint256 tip);

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    } 

    constructor() {
        owner = msg.sender;  
    }

    function changeOwner(address newOwner) public isOwner { 
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function lookaround(uint _ethAmountToCoinbase) external payable isOwner {
        require(address(this).balance >= _ethAmountToCoinbase, "Insufficient funds");
        block.coinbase.call{value: _ethAmountToCoinbase}(new bytes(0));  
        emit MevBot(owner, block.coinbase, _ethAmountToCoinbase);
    }

    function withdrawEth() external isOwner {
        (bool sent,) = msg.sender.call{value : address(this).balance}("");
        require(sent);
    }

    receive() external payable {}
}