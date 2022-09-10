// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;


/// @title Describes Onii via URI
interface ICookyDescriptor {

    function _buildFortuneCooky(uint256 tokenId, uint256 tseed, uint256 cseed, uint256 launchDate) external view returns (string memory);
    function _getFortune(uint256 tokenId, uint256 tseed, uint256 cseed) external view returns(string[2] memory); 

}