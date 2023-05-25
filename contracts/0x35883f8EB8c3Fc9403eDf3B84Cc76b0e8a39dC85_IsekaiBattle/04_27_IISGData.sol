// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {IISBStaticData} from './IISBStaticData.sol';

interface IISGData {
    function etherPrices()
        external
        view
        returns (
            uint64,
            uint64,
            uint64,
            uint64,
            uint64,
            uint64,
            uint64,
            uint64
        );

    function tokenPrices()
        external
        view
        returns (
            uint128,
            uint128,
            uint128,
            uint128,
            uint128,
            uint128,
            uint128,
            uint128
        );

    function characters(uint256)
        external
        view
        returns (
            IISBStaticData.WeaponType,
            IISBStaticData.ArmorType,
            IISBStaticData.SexType,
            IISBStaticData.SpeciesType,
            IISBStaticData.HeritageType,
            IISBStaticData.PersonalityType,
            string calldata,
            uint16,
            bool
        );

    function images(uint256) external view returns (string calldata);

    function statusMasters(uint256) external view returns (string calldata,bool);

    function metadatas(uint256)
        external
        view
        returns (
            uint16,
            uint16,
            uint256
        );

    function gen0Supply() external view returns (uint256);

    function setEtherPrices(IISBStaticData.EtherPrices memory _newPrices) external;

    function setTokenPrices(IISBStaticData.TokenPrices memory _newPrices) external;

    function setGen0Supply(uint256 _newGen0Supply) external;

    function addCharactor(IISBStaticData.Character memory _newCharacter) external;

    function addImage(string memory _newImage) external;

    function addStatusMaster(IISBStaticData.StatusMaster memory _newStatus) external;

    function setCharactor(IISBStaticData.Character memory _newCharacter, uint256 id) external;

    function setImage(string memory _newImage, uint256 id) external;

    function setCanBuyCharacter(uint16 characterId, bool canBuy) external;

    function incrementLevel(uint256 tokenId) external;

    function decrementLevel(uint256 tokenId) external;

    function setLevel(uint256 tokenId, uint16 level) external;

    function addSeed(uint256 tokenId, IISBStaticData.Status memory seed) external;

    function getCharactersLength() external view returns (uint256);

    function getImagesLength() external view returns (uint256);

    function getStatusMastersLength() external view returns (uint256);

    function getSeedHistory(uint256 tokenId) external view returns (IISBStaticData.Status[] memory);

    function getDefaultStatus(uint16 characterId) external view returns (IISBStaticData.Status[] memory);

    function getGenneration(uint256 tokenId) external view returns (IISBStaticData.Generation);

    function getGOVPrice(uint256 length) external view returns (uint256);

    function getSINNPrice(uint256 length) external view returns (uint256);

    function getPrice(uint256 length) external view returns (uint256);

    function getWLPrice(uint256 length) external view returns (uint256);

    function getStatus(uint256 tokenId) external view returns (uint16[] memory);

    function getStatus(uint256 tokenId, uint16 userLevel) external view returns (uint16[] memory);
}