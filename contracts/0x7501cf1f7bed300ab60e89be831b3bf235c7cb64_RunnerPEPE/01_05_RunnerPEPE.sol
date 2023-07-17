// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RunnerPEPE is ERC20 {

    uint256 public MAX_SUPPLY = 100_000_000 ether;

    constructor() ERC20("Runner PEPE", "RUNNERPEPE"){
        _mint(msg.sender, MAX_SUPPLY);
    }
}