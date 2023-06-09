// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface IERC721Descriptor {

    function tokenURI(uint256 tokenId, bytes memory data) external view returns (string memory uri);
}