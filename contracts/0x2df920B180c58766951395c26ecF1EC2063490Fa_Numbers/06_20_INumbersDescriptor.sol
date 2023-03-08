// SPDX-License-Identifier: MIT

/*********************************      
        numbers on chain     
 *********************************/

pragma solidity ^0.8.9;

interface INumbersDescriptor {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}