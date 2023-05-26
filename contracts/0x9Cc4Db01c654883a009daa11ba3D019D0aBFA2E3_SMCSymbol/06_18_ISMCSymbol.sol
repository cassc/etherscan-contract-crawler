// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISMCSymbolDescriptor {
    function tokenURI(ISMCManager manager, uint256 tokenId)
        external
        view
        returns (string memory);
}

interface ISMCSymbolData {
    function JapaneseZodiacs() external view returns (string[] memory);

    function Initials() external view returns (string[] memory);

    function Rarities() external view returns (string[] memory);

    function FirstNames() external view returns (string[] memory);

    function NativePlaces() external view returns (string[] memory);

    function Colors() external view returns (string[] memory);

    function Patterns() external view returns (string[] memory);
}

interface ISMCManager is IERC721 {
    function getRespect() external view returns (string memory);

    function getRespectColorCode() external view returns (uint256);

    function getCodesOfArt(uint256 tokenId)
        external
        view
        returns (string memory);

    function getRarity(uint256 tokenId) external view returns (string memory);

    function getRarityDigit(uint256 tokenId) external view returns (uint256);

    function getSamurights(uint256 tokenId) external view returns (uint256);

    function getName(uint256 tokenId) external view returns (string memory);

    function getNativePlace(uint256 tokenId)
        external
        view
        returns (string memory);

    function getJapaneseZodiac(uint256 tokenId)
        external
        view
        returns (string memory);

    function getColorLCode(uint256 tokenId) external view returns (uint256);

    function getColorL(uint256 tokenId) external view returns (string memory);

    function getColorRCode(uint256 tokenId) external view returns (uint256);

    function getColorR(uint256 tokenId) external view returns (string memory);

    function getPatternLCode(uint256 tokenId) external view returns (uint256);

    function getPatternL(uint256 tokenId) external view returns (string memory);

    function getPatternRCode(uint256 tokenId) external view returns (uint256);

    function getPatternR(uint256 tokenId) external view returns (string memory);

    function getActivatedKatana(uint256 tokenId)
        external
        view
        returns (string memory);
}