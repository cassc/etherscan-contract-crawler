//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Polly.sol";

abstract contract PollyAux {

  struct Msg {
    address _sender;
    uint _value;
    bytes _data;
    bytes4 _sig;
  }

  fallback() external {}
  function hooks() external view virtual returns (string[] memory);
  function filter(string memory, uint, Polly.Param memory, Msg memory msg_) external view virtual returns (Polly.Param memory) {}
  function filter(string memory, uint, string memory, Msg memory msg_) external view virtual returns (string memory) {}
  function filter(string memory, uint, uint, Msg memory msg_) external view virtual returns (uint) {}
  function filter(string memory, uint, address, Msg memory msg_) external view virtual returns (address) {}
  function filter(string memory, uint, bool, Msg memory msg_) external view virtual returns (bool) {}

}



abstract contract PollyAuxParent {

  mapping(string => address) internal _aux_hooks;

  function registerAux(address aux_) public virtual;
  function _registerHooks(string[] memory hooks_, address aux_) internal {
    for (uint i = 0; i < hooks_.length; i++){
      _aux_hooks[hooks_[i]] = aux_;
    }
  }

  function getHookAddress(string memory hook_) public view returns (address) {
    return _aux_hooks[hook_];
  }

}