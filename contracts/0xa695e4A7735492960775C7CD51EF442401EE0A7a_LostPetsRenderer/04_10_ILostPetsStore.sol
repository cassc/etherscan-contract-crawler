// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.14;

interface ILostPetsStore {
    // function getBaseURI() external view returns (string memory);

    function getPetName(uint256 id) external view returns (string memory);
    function getPetHood(uint256 id) external view returns (string memory);
    function getPetBreed(uint256 id) external view returns (string memory);
    function getPetState(uint8 id) external view returns (string memory);
    function getPetHasReward(uint8 id) external view returns (string memory);
    function getPetPallete(uint8 id) external view returns (string memory);

    function getPetBorough(uint8 id) external view returns (string memory);
    function getPetType(uint8 id) external view returns (string memory);
    function getPetColors(uint8 id) external view returns (string memory);


    function getRawPetData(uint256 id) external view returns (bytes memory);
}