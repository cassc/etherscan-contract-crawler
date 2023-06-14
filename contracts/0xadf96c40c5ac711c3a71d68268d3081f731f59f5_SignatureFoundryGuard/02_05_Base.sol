// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Interface.sol";

contract BaseFoundryGuard is FoundryGuardInterface {
  function authorize(
    uint256,
    address,
    string calldata,
    bytes calldata
  ) external view virtual override returns (bool) {
    return true;
  }
}