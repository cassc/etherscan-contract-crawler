// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

interface IMetadataProxy {
    function tokenURI(uint256 tokenId, uint128 workingPeriod)
        external
        view
        returns (string memory);
}