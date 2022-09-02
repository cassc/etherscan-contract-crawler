// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ScapesCollectible.sol";
import "./strings.sol";

contract SpeechBubbles is ScapesCollectible  {
    using strings for *;

    constructor (address archive)
        ScapesCollectible(
            "Speech Bubbles by Scapes",
            "SPEECH",
            "Let your NFTs talk on chain.",
            archive
        )
    {}

    /// @dev Override this to add a custom name
    function _name(uint256 tokenId)
        override internal view
        returns (string memory name)
    {
        (name,,) = _config(tokenId);
    }

    /// @dev Override this to add custom attributes
    function _attributes(uint256 tokenId)
        override internal view
        returns (string memory)
    {
        (, string memory direction, string memory origin) = _config(tokenId);

        return string.concat(
            '"attributes":[{"trait_type":"Origin","value":"',
            origin,
            '"},{"trait_type":"Direction","value":"',
            direction,
            '"}],'
        );
    }

    /// @dev Parse the directional data from the name
    function _config(uint256 tokenId)
        private view
        returns (string memory, string memory, string memory)
    {
        strings.slice memory name = _names[tokenId].toSlice();
        strings.slice memory direction = name.rsplit(" ".toSlice());
        strings.slice memory origin = name.rsplit(" ".toSlice());
        return (name.toString(), direction.toString(), origin.toString());
    }

}