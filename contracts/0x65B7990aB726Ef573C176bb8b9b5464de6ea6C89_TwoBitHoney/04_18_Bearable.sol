// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IBearable.sol";
import "../nfts/TwoBitBears.sol";

/// @title Bearable base contract for accessing a deployed TwoBitBears ERC721
/// @dev You may inherit or deploy separately
contract Bearable is IBearable {

    /// @dev Stores the address to the deployed TwoBitBears contract
    TwoBitBears internal immutable _twoBitBears;

    /// Constructs a new instance of the Bearable contract
    /// @param twoBitBears The address of the twoBitBears contract on the deployment blockchain
    constructor(address twoBitBears) {
        _twoBitBears = TwoBitBears(twoBitBears);
    }

    /// @inheritdoc IBearable
    /// @dev Throws if the token ID is not valid. Requirements already handled by the .ownerOf() call
    function ownsBear(address possibleOwner, uint256 tokenId) public view override returns (bool) {
        return _twoBitBears.ownerOf(tokenId) == possibleOwner;
    }

    /// @inheritdoc IBearable
    function totalBears() public view override returns (uint256) {
        return _twoBitBears.totalSupply();
    }

    /// @inheritdoc IBearable
    /// @dev Throws if the token ID is not valid. Requirements already handled by the .details() call
    function bearBottomColor(uint256 tokenId) public view override returns (ISVG.Color memory color) {
        IBearDetail.Detail memory details = _twoBitBears.details(tokenId);
        color.red = details.bottomColor.red;
        color.green = details.bottomColor.green;
        color.blue = details.bottomColor.blue;
        color.alpha = 0xFF;
    }

    /// @inheritdoc IBearable
    /// @dev Throws if the token ID is not valid. Requirements already handled by the .details() call
    function bearMood(uint256 tokenId) public view override returns (BearMoodType) {
        IBearDetail.Detail memory details = _twoBitBears.details(tokenId);
        return BearMoodType(details.moodIndex);
    }

    /// @inheritdoc IBearable
    /// @dev Throws if the token ID is not valid. Requirements already handled by the .details() call
    function bearSpecies(uint256 tokenId) public view override returns (BearSpeciesType) {
        IBearDetail.Detail memory details = _twoBitBears.details(tokenId);
        return BearSpeciesType(details.speciesIndex);
    }

    /// @inheritdoc IBearable
    /// @dev Throws if the token ID is not valid. Requirements already handled by the .details() call
    function bearTopColor(uint256 tokenId) public view override returns (ISVG.Color memory color) {
        IBearDetail.Detail memory details = _twoBitBears.details(tokenId);
        color.red = details.topColor.red;
        color.green = details.topColor.green;
        color.blue = details.topColor.blue;
        color.alpha = 0xFF;
    }
}