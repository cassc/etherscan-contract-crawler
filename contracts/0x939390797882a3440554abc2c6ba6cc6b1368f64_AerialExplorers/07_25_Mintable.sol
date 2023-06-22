// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

abstract contract Mintable {
    function _mint(address to, uint256 quantity) internal virtual;

    function _mintCount(address owner) internal view virtual returns (uint256);
}