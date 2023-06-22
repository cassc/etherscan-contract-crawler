// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Accountable is Context {
    address[] private splits;
    uint256[] private splitWeights;

    mapping(address => uint256) private splitAmounts;

    event WithdrawProcessed(
        address indexed ownerWithdrawing,
        uint256 indexed amount
    );

    constructor(address[] memory _splits, uint256[] memory _splitWeights) {
        splits = _splits;
        splitWeights = _splitWeights;
    }

    modifier hasSplits() {
        require(splits.length > 0, "Splits have not been set.");
        require(splitWeights.length > 0, "Split weights have not been set.");
        _;
    }
    
    // Returns the splitAmount in wei.
    function getSplitBalance(address _address) public view returns (uint256) {
        return splitAmounts[_address];
    }

    // With this each team member can withdraw their cut at anytime they like. 
    // Must be a real amount that is greater than zero and within their available balance.
    function withdrawSplit(uint256 _amount) external hasSplits {
        require(_amount > 0, "Withdrawals of 0 cannot take place.");
        require(
            splitAmounts[msg.sender] >= _amount,
            "This value is more than available to withdraw."
        );

        splitAmounts[msg.sender] -= _amount;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed.");
        emit WithdrawProcessed(msg.sender, _amount);
    }

    // This should be run in any function that is paying the contract.
    // At the time of minting we are crediting each team member with the proper amount.
    function tallySplits() internal hasSplits {
        uint256 each;
        for (uint256 i; i < splits.length; i++) {
            each = ((msg.value * splitWeights[i] / 100000));
            splitAmounts[splits[i]] += each;
        }
    }
}