// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IERC1155Mintable {
    function mint(address to, uint256 tokenId, uint amount) external;
}