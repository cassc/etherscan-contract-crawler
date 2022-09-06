//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMMNFT {
    function adminMint(uint256 count, address to) external;
    function mint(address to, uint256 rarirty) external;
    function adminMint(uint256 count, address to, uint256 rarity) external;
    function burn(uint256 tokenId) external;
    function totalSupply() external view returns (uint256);
    function supply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}