// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

interface IBabylonMintPass {
    function initialize(
        uint256 listingId_,
        address core_
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address from) external returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}