//Made with Student Coin Terminal
//SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

abstract contract Configurable {
  // enum
  enum State {
    UNCONFIGURED,
    CONFIGURED
  }

  // storage
  State public state = State.UNCONFIGURED;

  // modifier
  modifier onlyInState(State _state) {
    require(state == _state, "Invalid state");
    _;
  }
}