// SPDX-License-Identifier: MIT

/// @author notu @notuart

pragma solidity ^0.8.9;

import '../interfaces/IShared.sol';

interface IWorkshop is IShared {
  function render(
    uint256 tokenId,
    address owner,
    string calldata name,
    uint256 birthdate,
    Attributes calldata attributes
  ) external view returns (string memory);
}