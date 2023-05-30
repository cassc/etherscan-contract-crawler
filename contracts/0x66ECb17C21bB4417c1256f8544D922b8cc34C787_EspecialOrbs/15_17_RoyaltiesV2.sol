// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import "./library/LibPart.sol";

interface RoyaltiesV2 {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory);
}