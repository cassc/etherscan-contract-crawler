// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface INToken {
    function factory() external view returns(address);
    
    function nft() external view returns(address);

    event Mint(address indexed from, uint256 tokenId);

    function mint(address user, uint256 tokenId) external;

    event Burn(address indexed from, address indexed target, uint256 tokenId);

    function burn(address user, address receiverOfUnderlying, uint256 tokenId) external;

    event NFTTransfered(address indexed collection, address indexed recipient, uint256 indexed tokenId);

    function transferERC721(address collection, address recipient, uint256 tokenId) external;
}