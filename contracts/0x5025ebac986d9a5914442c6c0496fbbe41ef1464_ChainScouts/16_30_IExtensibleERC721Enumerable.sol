//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IExtensibleERC721Enumerable is IERC721Enumerable {
    function isAdmin(address addr) external view returns (bool);

    function addAdmin(address addr) external;

    function removeAdmin(address addr) external;

    function canAccessToken(address addr, uint tokenId) external view returns (bool);

    function adminBurn(uint tokenId) external;

    function adminTransfer(address from, address to, uint tokenId) external;
}