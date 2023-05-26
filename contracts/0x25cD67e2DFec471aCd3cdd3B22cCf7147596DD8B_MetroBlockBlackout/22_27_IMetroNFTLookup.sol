// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.12;

interface IMetroNFTLookup {

    function getNFTContractAddress(uint256 tokenId) external view returns (address);
}