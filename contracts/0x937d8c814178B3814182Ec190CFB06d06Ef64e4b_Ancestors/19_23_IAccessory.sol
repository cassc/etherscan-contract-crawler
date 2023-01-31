// contracts/IAccessory.sol
// SPDX-License-Identifier: BUSL

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IAccessory is IERC1155 {
    function accessoryType(uint256 _tokenId) external returns (uint256);
}