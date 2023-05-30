//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface ILostPetsRenderer {
    function getLostPetSVG(uint256 id) external view returns (string memory);

    function tokenURI(uint256 id) external view returns (string memory);
}