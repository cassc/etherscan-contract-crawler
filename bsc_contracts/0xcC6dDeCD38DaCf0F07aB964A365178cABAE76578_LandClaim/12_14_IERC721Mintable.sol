// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IERC721Mintable {
    function mint(address to, uint256 tokenId) external;
}