// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

pragma solidity >=0.7.0 <0.9.0;

contract MultiSender {
    using SafeMath for uint256;

    constructor() {}
    
    // withdrawls enable to multiple withdraws to different accounts
    // at one call, and decrease the network fee
    function multisend(address payable[] memory addresses, uint256[] memory amounts) payable public {
        uint256 total = msg.value;

        // the addresses and amounts should be same in length and less or equal than 100
        require(addresses.length == amounts.length && addresses.length <= 100, "The length of two array should be the same and less or equal than 100");
        
        for (uint i=0; i < addresses.length; i++) {
            // the total should be greater than the sum of the amounts
            require(total >= amounts[i], "The value is not sufficient or exceed");
            total.sub(amounts[i]);
            
            // send the specified amount to the recipient
            addresses[i].transfer(amounts[i]);
        }
    }
}