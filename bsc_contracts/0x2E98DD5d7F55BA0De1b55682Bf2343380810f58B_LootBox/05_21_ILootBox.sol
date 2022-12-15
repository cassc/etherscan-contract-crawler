// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILootBox is IERC721 {
    function updateManagement(address _newManagement) external;

    function updateClassDropRate(
        uint8 _boxRarity,
        uint8 _microphoneClass,
        uint256 _dropRate
    ) external;

    function updateKindDropRates(
        uint8 _classCol1,
        uint8 _classCol2,
        uint256[] calldata _dropRates
    ) external;

    function mint(
        address _to,
        uint8 _rarity,
        uint8 _matronType,
        uint8 _sireType
    ) external;

    function setBaseURI(string memory _uri) external;

    function unbox(uint256 _tokenId) external;
}