//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IGPC is IERC1155 {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);
}

interface IGPC721 is IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IPandaNFT {
    function getMintTime(uint256 _tokenId) external view returns (uint256);
}