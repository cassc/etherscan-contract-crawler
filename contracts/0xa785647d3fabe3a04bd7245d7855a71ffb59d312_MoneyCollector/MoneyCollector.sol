/**
 *Submitted for verification at Etherscan.io on 2023-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

error MoneyCollectorNotOwner();

contract MoneyCollector {

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    address public /* immutable */ i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    function contractInteraction() public payable {
        require(msg.value >= 0, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    modifier onlyOwner {
        if (msg.sender != i_owner) revert MoneyCollectorNotOwner();
        _;
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    fallback() external payable {
        contractInteraction();
    }

    receive() external payable {
        contractInteraction();
    }

}