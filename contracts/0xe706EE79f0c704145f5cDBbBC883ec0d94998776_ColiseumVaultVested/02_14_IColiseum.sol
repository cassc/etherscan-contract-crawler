//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IColiseum {
    function isController(address _address) external view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external payable;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

}