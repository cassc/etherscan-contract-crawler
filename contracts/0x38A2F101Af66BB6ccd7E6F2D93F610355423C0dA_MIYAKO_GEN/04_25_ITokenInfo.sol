// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ITokenInfoInterface {
    function createTokenURI(uint256 _tokenId) external  view returns (string memory);
    function isPermitted(address operator)external view returns(bool);
    function isPermitted(address owner ,address operator)external view returns(bool);
    function isPermitted(address operator ,uint256 _tokenId)external view returns(bool);
    function isLock(address to ,uint256 _tokenId)external view returns(bool);
    function isLock(address to ,uint256 _tokenId ,address sender)external view returns(bool);
    function init(address to,uint256 _tokenId)external;
}