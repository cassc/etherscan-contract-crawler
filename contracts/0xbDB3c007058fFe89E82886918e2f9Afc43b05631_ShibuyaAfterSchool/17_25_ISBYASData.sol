// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ISBYASStaticData} from './ISBYASStaticData.sol';

interface ISBYASData {
    function characters(
        uint256
    )
        external
        view
        returns (
            ISBYASStaticData.Hair,
            ISBYASStaticData.HairColor,
            ISBYASStaticData.EyeColor,
            ISBYASStaticData.SchoolUniform,
            ISBYASStaticData.Accessory,
            string calldata,
            uint256
        );

    function etherPrice() external view returns (uint64);

    function images(uint256) external view returns (string calldata);

    function setEtherPrice(uint64 _newPrice) external;

    function addCharactor(ISBYASStaticData.Character memory _newCharacter) external;

    function addImage(string memory _newImage) external;

    function setCharactor(ISBYASStaticData.Character memory _newCharacter, uint256 id) external;

    function setImage(string memory _newImage, uint256 id) external;

    function getCharactersLength() external view returns (uint256);

    function getImagesLength() external view returns (uint256);
}