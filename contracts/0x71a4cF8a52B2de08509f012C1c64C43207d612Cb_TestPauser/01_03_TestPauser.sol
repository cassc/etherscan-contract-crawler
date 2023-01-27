// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract TestPauser is Ownable {
  event Paused(address account, uint value);

  function fib(uint n) private returns(uint) { 
    if (n <= 1) {
       return n;
    } else {
       return fib(n - 1) + fib(n - 2);
    }
  }

  function pauseAllContracts()
      external
      onlyOwner
  {
      // this is just to burn some gas, and make transaction surpass flashbots minimum of 42000 gas
      // with fib = 8 it cost around 50k gas
      uint v = fib(8);
      emit Paused(msg.sender, v);
  }
}