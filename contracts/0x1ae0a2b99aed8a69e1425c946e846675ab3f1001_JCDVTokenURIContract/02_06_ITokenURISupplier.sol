// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ITokenURISupplier is IERC165 {
  function tokenURI(uint256 id) external view returns (string memory);
}