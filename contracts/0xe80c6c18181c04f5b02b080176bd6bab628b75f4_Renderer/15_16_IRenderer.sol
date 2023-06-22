// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IProofOfVisit} from "./IProofOfVisit.sol";

interface IRenderer {
    function imageUrl(uint256 tokenId) external view returns (string memory);
    function animationUrl(uint256 tokenId, IProofOfVisit.TokenAttribute memory tokenAttribute) external view returns (string memory);
}