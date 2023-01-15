// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface ITokenURI{
    function tokenURI(uint256 _tokenId) external view returns(string memory);
}