// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibERC165} from "./LibERC165.sol";
import {ERC165Storage} from "./ERC165Storage.sol";
import {IERC165} from "./IERC165.sol";

contract ERC165Facet is IERC165 {
  // This implements ERC-165.
  function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
    ERC165Storage storage ds = LibERC165.DS();
    return ds.supportedInterfaces[_interfaceId];
  }
}