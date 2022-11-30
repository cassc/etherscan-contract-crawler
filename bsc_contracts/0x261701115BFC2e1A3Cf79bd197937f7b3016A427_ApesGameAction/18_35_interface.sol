// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721 {
    event Mint(address indexed to, uint256 indexed tokenId);

    function adminMintTo(address to, uint256 tokenId) external;
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external;

    function transfer(address recipient, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function adminMint(address account, uint256 amount) external;
}