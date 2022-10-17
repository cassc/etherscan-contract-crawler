// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./LibPart.sol";

interface IRoyalties {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getOrderinboxRoyalties(uint256 id) external view returns (LibPart.Part[] memory);
}