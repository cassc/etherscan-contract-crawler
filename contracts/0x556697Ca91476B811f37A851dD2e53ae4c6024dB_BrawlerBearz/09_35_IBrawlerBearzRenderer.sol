//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBrawlerBearzCommon} from "./IBrawlerBearzCommon.sol";

interface IBrawlerBearzRenderer is IBrawlerBearzCommon {
    function hiddenURI(uint256 _tokenId) external view returns (string memory);

    function tokenURI(
        uint256 _tokenId,
        uint256 _seed,
        CustomMetadata memory _md
    ) external view returns (string memory);

    function dna(
        uint256 _tokenId,
        uint256 _seed,
        CustomMetadata memory _md
    ) external view returns (string memory);
}