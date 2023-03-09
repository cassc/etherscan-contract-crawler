// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IWarm {
    function ownerOf(
        address contractAddress,
        uint256 tokenId
    ) external view returns (address);
}