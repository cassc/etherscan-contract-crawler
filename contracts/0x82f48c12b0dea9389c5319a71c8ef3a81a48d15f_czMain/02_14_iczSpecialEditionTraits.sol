// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface iczSpecialEditionTraits is IERC721Enumerable {

    // traits meta data
    struct Trait {
        string name;
        uint16 traitId;
        uint256 price; // in eth
        uint16 maxMint; // max mint for this trait
        uint16 minted; // how often this trait has been minted already
    }

    struct Token {
        uint16 tokenId;
        uint16 traitId;
    }

    function totalMinted() external view returns (uint16);
    function totalBurned() external view returns (uint16);

    function mint(uint16 traitId, address recipient) external; // onlyAdmin
    function burn(uint16 tokenId) external;
    
    function getToken(uint16 tokenId) external view returns (Token memory token);
    function getTrait(uint16 traitId) external view returns (Trait memory trait);
    function getWalletOfOwner(address owner) external view returns (uint256[] memory);
}