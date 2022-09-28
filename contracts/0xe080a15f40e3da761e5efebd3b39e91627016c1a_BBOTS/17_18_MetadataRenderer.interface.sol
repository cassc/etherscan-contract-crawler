// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IMetadataRenderer {
    /*///////////////////////////////////////////////////////////////
                        	   RENDERING
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 id) external view returns (string memory);
}