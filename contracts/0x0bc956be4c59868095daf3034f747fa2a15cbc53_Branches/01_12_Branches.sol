// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ScapesCollectible.sol";
import "./strings.sol";

contract Branches is ScapesCollectible  {
    using strings for *;

    constructor (address archive)
        ScapesCollectible(
            "Branches by Scapes",
            "BRANCHES",
            "Birbs need a spot to sit, right?",
            archive
        )
    {}

    /// @dev Override this to add a custom name
    function _name(uint256 tokenId)
        override internal view
        returns (string memory name)
    {
        (name,) = _config(tokenId);
    }

    /// @dev Override this to add custom attributes
    function _attributes(uint256 tokenId)
        override internal view
        returns (string memory)
    {
        (, string memory alignment) = _config(tokenId);

        return string.concat(
            '"attributes":[{"trait_type":"Alignment","value":"',
            alignment,
            '"}],'
        );
    }

    /// @dev Parse the directional data from the name
    function _config(uint256 tokenId)
        private view
        returns (string memory, string memory)
    {
        strings.slice memory name = _names[tokenId].toSlice();
        strings.slice memory alignment = name.rsplit(" ".toSlice());
        return (name.toString(), alignment.toString());
    }
}