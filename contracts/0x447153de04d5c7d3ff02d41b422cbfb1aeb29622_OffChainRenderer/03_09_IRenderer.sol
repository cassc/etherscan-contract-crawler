// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Structs.sol";
import "./IArtData.sol";

interface IRenderer {

    function render(
        string calldata tokenSeed,
        uint256 tokenId,
        BaseAttributes memory atts,
        bool isSample,
        IArtData.ArtProps memory artProps
    )
        external
        view
        returns (string memory);

}