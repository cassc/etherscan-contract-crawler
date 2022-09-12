// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IHouseGame is IERC721Upgradeable {
    function getPropertyDamage(uint256 tokenId)
        external
        view
        returns (uint256 _propertyDamage);

    function getIncomePerDay(uint256 tokenId)
        external
        view
        returns (uint256 _incomePerDay);

    function getHousePaidTokens() external view returns (uint256);

    function getBuildingPaidTokens() external view returns (uint256);

    function getTokenTraits(uint256 tokenId)
        external
        view
        returns (HouseBuilding memory);

    // struct to store each token's traits
    struct HouseBuilding {
        bool isHouse;
        uint8 model;
        uint256 imageId;
    }
}