// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import "../libraries/rarible/LibPart.sol";

interface IRaribleRoyaltiesV2 {

    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory);
}