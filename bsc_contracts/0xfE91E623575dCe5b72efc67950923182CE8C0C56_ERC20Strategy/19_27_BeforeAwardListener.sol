// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IBeforeAwardListener.sol";

abstract contract BeforeAwardListener is IBeforeAwardListener, ERC165 {
  function supportsInterface(bytes4 interfaceId) public override(ERC165, IERC165) view returns (bool) {
    return (
      interfaceId == type(IBeforeAwardListener).interfaceId || 
      super.supportsInterface(interfaceId)
    );
  }
}