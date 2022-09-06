// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

interface IExtensionAccess {
    function getOperator(uint256 tokenId) external view returns (address);
    function getOwner(uint256 tokenId) external view returns (address);
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);
}