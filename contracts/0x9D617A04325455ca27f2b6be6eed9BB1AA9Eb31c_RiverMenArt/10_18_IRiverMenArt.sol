// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma abicoder v2;

interface IRiverMenArt {
    /* ================ EVENTS ================ */
    event Mint(address indexed payer, uint256 indexed tokenId);

    /* ================ VIEWS ================ */

    function tokenResource(uint256 tokenId) external view returns (uint24);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    /* ================ ADMIN ACTIONS ================ */
    function setBaseURI(string memory newBaseURI) external;

    function batchMint(address[] memory receivers, uint16[] memory resourceIds) external;
}