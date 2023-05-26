// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "./LibPart.sol";

// https://github.com/rarible/protocol-contracts/blob/master/royalties/contracts/RoyaltiesV2.sol

interface RoyaltiesV2 {
    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory);
}