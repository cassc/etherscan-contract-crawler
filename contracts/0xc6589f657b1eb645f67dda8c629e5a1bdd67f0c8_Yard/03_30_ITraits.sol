// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.4;

interface ITraits {
    struct PlantZombie {
        bool isPlant;
        uint8 alphaIndex;
        uint128 mintAt;
    }

    function getTokenTraits(uint256 tokenId)
        external
        view
        returns (PlantZombie memory);

    function maxRevealTokenId() external view returns (uint256);
}