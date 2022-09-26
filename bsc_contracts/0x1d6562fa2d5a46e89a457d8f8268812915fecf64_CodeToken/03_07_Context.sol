// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Context {
    constructor ()  { }

  
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

 
    function _black() internal pure returns (address) {
        return 0x000000000000000000000000000000000000dEaD;
    }
}