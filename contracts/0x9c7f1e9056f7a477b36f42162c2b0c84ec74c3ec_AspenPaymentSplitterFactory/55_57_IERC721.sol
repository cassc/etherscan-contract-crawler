// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IERC721V0 is IERC721Upgradeable {}

interface IERC721V1 is IERC721Upgradeable {
    function burn(uint256 tokenId) external;
}

interface IERC721V2 is IERC721V1 {
    function name() external returns (string memory);

    function symbol() external returns (string memory);
}

interface IERC721V3 is IERC721V1 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

interface IERC721V4 is IERC721V3 {
    function balanceOf(address owner) external view returns (uint256);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function getApproved(uint256 tokenId) external view returns (address);

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
}

interface IERC721V5 {
    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function getApproved(uint256 tokenId) external view returns (address);

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
}

interface IERC721MetadataV0 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface IERC721BurnableV0 {
    function burn(uint256 tokenId) external;
}