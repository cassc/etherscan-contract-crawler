// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface IFlashNFT {
    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function burn(uint256 _tokenId) external returns (bool);

    function contractURI() external pure returns (string memory);

    function exists(uint256 _tokenId) external view returns (bool);

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function mint(address _recipientAddress) external returns (uint256);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function renounceOwnership() external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferOwnership(address newOwner) external;
}