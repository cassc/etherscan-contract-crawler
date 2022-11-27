//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IGPC is IERC1155 {
    function burn(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) external;

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

    function _safeMint(address to, uint256 quantity,uint256 tokenId) external view;
    function currentMaxSupply() external view returns (uint256 currentMaxSupply);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )external view ; 
}

interface IPandaNFT {
    function getMintTime(uint256 _tokenId) external view returns (uint256);
}