// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IFlipmap{
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenDataOf(uint256 tokenId) external view returns (bytes memory) ;
    function tokenParentsOf(uint256 tokenId) external view returns (uint256, uint256);
    function tokenSvgDataOf(uint256 tokenId) external view returns (string memory);
}