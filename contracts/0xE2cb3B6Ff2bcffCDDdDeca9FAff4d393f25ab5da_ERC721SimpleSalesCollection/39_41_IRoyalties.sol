// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
pragma abicoder v2;

import "./LibPart.sol";

interface IRoyalties {
    function getRaribleV2Royalties(uint256 id)
        external
        view
        returns (LibPart.Part[] memory);
}