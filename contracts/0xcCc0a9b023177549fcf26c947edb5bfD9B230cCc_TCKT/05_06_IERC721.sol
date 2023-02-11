// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721 {
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function balanceOf(address) external view returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function supportsInterface(bytes4 interfaceId) external pure returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
}