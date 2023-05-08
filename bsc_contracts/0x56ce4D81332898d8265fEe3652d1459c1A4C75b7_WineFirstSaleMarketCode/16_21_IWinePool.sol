// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWinePool
{
//////////////////////////////////////// DescriptionFields

    function updateAllDescriptionFields(
        string memory wineName,
        string memory wineProductionCountry,
        string memory wineProductionRegion,
        string memory wineProductionYear,
        string memory wineProducerName,
        string memory wineBottleVolume,
        string memory linkToDocuments
    ) external;
    function editDescriptionField(bytes32 param, string memory value) external;

//////////////////////////////////////// System fields

    function getPoolId() external view returns (uint256);
    function getMaxTotalSupply() external view returns (uint256);
    function getWinePrice() external view returns (uint256);

    function editMaxTotalSupply(uint256 value) external;
    function editWinePrice(uint256 value) external;

//////////////////////////////////////// Pausable

    function pause() external;
    function unpause() external;

//////////////////////////////////////// Initialize

    function initialize(
        string memory name,
        string memory symbol,

        address manager,

        uint256 poolId,
        uint256 maxTotalSupply,
        uint256 winePrice
    ) external payable returns (bool);

//////////////////////////////////////// Disable

    function disabled() external view returns (bool);

    function disablePool() external;

//////////////////////////////////////// default methods

    function tokensCount() external view returns (uint256);

    function burn(uint256 tokenId) external;

    function mint(address to) external;

//////////////////////////////////////// internal users and tokens


    event WinePoolMintToken(address to, uint256 tokenId, uint256 poolId);
    event WinePoolMintTokenToInternal(address to, uint256 tokenId, uint256 poolId);
    event OuterToInternalTransfer(address from, address to, uint256 tokenId, uint256 poolId);
    event InternalToInternalTransfer(address from, address to, uint256 tokenId, uint256 poolId);
    event InternalToOuterTransfer(address from, address to, uint256 tokenId, uint256 poolId);

    function internalUsersExists(address) external view returns (bool);
    function internalOwnedTokens(uint256) external view returns (address);

    function mintToInternalUser(address internalUser) external;

    function transferInternalToInternal(address internalFrom, address internalTo, uint256 tokenId) external;

    function transferOuterToInternal(address outerFrom, address internalTo, uint256 tokenId) external;

    function transferInternalToOuter(address internalFrom, address outerTo, uint256 tokenId) external;

}