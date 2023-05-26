//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


interface IENSToken {
    function nameExpires(uint256 id) external view returns(uint256);
    function reclaim(uint256 id, address addr) external;
    function setResolver(address _resolverAddress) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}