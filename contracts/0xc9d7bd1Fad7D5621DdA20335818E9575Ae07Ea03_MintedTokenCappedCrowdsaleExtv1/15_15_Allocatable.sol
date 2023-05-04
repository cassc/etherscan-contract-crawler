// SPDX-License-Identifier: MIT


pragma solidity 0.7.6;

import "./Ownable.sol";


contract Allocatable is Ownable {

  /** List of agents that are allowed to allocate new tokens */
    mapping (address => bool) public allocateAgents;

    event AllocateAgentChanged(address addr, bool state  );

  /**
   * Owner can allow a crowdsale contract to allocate new tokens.
   */
    function setAllocateAgent(address addr, bool state) public onlyOwner  
    {
        allocateAgents[addr] = state;
        emit AllocateAgentChanged(addr, state);
    }

    modifier onlyAllocateAgent() {
        //Only crowdsale contracts are allowed to allocate new tokens
        require(allocateAgents[msg.sender]);
        _;
    }
}