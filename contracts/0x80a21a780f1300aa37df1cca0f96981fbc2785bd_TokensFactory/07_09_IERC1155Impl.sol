// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IERC1155Impl is IERC1155Upgradeable{
    function __ERC1155Impl_init(string memory uri, address owner) external;
}