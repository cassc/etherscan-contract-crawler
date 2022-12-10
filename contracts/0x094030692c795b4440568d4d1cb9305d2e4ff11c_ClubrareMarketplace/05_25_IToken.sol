// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IToken {
    // Required methods
    function ownerOf(uint256 _tokenId) external view returns (address owner);

    function royalities(uint256 _tokenId) external view returns (uint256);

    function creators(uint256 _tokenId) external view returns (address payable);

    function safeMint(string memory uri, uint256 value) external returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function burn(uint256 tokenId) external;

    function mint(string calldata _tokenURI, uint256 _royality) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}