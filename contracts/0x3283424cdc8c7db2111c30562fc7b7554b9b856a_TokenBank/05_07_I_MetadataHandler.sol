// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface I_MetadataHandler {

    function tokenURI(uint256 tokenID) external view returns (string memory); //our implementation may even be pure

}