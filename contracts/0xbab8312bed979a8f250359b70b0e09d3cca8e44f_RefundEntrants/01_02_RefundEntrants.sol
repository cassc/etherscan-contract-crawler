// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Owned} from "solmate/auth/Owned.sol";

contract RefundEntrants is Owned(msg.sender) {
    mapping (address => uint256) public entrantBalance;
    uint public pot = 0;
    uint constant ENTRY_FEE = 0.08 ether;

    error ZeroBalance();

    /// @notice load entrants
    /// @param entrants addresses who called "enter"
    /// @param numEntered number of times they entered 
    function load(address[] memory entrants, uint[] memory numEntered) public onlyOwner {
        require(entrants.length == numEntered.length, "different length arrays");
        for (uint i=0; i < entrants.length; i++) {
            entrantBalance[entrants[i]] = numEntered[i] * ENTRY_FEE;
            pot += numEntered[i] * ENTRY_FEE;
        }
    }

    function withdraw() public payable {
        uint amount = entrantBalance[msg.sender];
        if (amount == 0){
            revert ZeroBalance();
        }
        entrantBalance[msg.sender] = 0;
        (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    /// @notice sweep ETH out of contract
    function sweepEth() public onlyOwner {
         (bool sent, bytes memory data) = owner.call{value: address(this).balance}("");
         require(sent, "Failed to send Ether");
    }

    receive() external payable {}
    fallback() external payable {} 
}