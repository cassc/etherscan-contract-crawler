//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { ERC165 } from "@openzeppelin/contracts/introspection/ERC165.sol";

abstract contract OnApprove is ERC165 {
  constructor() {
    _registerInterface(OnApprove(this).onApprove.selector);
  }

  function onApprove(address owner, address spender, uint256 amount, bytes calldata data) external virtual returns (bool);
}