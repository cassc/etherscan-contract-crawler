/**
 *Submitted for verification at BscScan.com on 2022-10-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract SwissKnife {
    address public storedCoinbase;

    constructor() {
      storedCoinbase = block.coinbase;
    }

    function blockCoinbase() public view returns (address) {
      return block.coinbase;
    }
}