//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
interface IRandomEdition
{
    function _Mint(address Recipient, uint Amount) external returns(uint tokenID); // Mints Random Edition
    function purchaseTo(address Recipient) external returns(uint tokenID); // Mints Random Edition
    function tokenURI(uint256 tokenId) external view returns (string memory); // Returns IPFS Metadata
}