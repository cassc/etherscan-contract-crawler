// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Interface.sol";

contract BaseFoundryValidator is FoundryValidatorInterface {
  function validate(uint256, string calldata)
    external
    view
    virtual
    override
    returns (bool)
  {
    return true;
  }
}