// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IWnD is IERC721Enumerable {

    // game data storage
    struct WizardDragon {
        bool isWizard;
        uint8 body;
        uint8 head;
        uint8 spell;
        uint8 eyes;
        uint8 neck;
        uint8 mouth;
        uint8 wand;
        uint8 tail;
        uint8 rankIndex;
    }

    function minted() external returns (uint16);
    function updateOriginAccess(uint16[] memory tokenIds) external;
    function mint(address recipient, uint256 seed) external;
    function burn(uint256 tokenId) external;
    function getMaxTokens() external view returns (uint256);
    function getPaidTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (WizardDragon memory);
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function isWizard(uint256 tokenId) external view returns(bool);
  
}