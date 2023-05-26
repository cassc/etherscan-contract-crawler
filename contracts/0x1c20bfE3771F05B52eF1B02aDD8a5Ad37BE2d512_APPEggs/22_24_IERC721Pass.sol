// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IEnjoyPassport.sol";

interface IERC721Pass is IEnjoyPassport{
    function ownerOf(uint256 tokenId) external view returns(address);
    function balanceOf(address owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}