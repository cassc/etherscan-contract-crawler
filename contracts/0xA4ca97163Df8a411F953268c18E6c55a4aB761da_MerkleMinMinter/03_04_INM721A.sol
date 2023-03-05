// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface INM721A {
    function setBaseURI(string calldata _baseURI) external;
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external;
    function mint(address _recipient, uint256 _quantity) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function approve(address operator, uint256 tokenId) external payable;
    function getApproved(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external payable;
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external payable;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
    function ADMIN_ROLE() external view returns (bytes32);
    function MINTER_ROLE() external view returns (bytes32);
    function hasRole(bytes32 role, address account) external view returns (bool);
}