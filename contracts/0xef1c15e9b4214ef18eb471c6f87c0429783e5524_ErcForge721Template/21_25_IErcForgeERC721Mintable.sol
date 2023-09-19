//SPDX-License-Identifier: CC-BY-NC-ND

pragma solidity ^0.8.0;

interface IErcForgeERC721Mintable {
    function mint(address to) external payable;
}