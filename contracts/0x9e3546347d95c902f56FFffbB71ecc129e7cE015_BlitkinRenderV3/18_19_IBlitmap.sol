// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IBlitmap{
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenCreatorOf(uint256 tokenId) external view returns (address);
    function tokenDataOf(uint256 tokenId) external view returns (bytes memory) ;
    function tokenNameOf(uint256 tokenid) external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function remainingNumOriginals() external view returns (uint8);
    function allowedNumOriginals() external view returns (uint8);
    function tokenIsOriginal(uint256 tokenId) external view returns (bool);
}