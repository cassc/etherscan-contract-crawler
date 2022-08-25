// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IOpenSkyNFTDescriptor {
    function tokenURI(uint256 reserveId)
        external
        view
        returns (string memory);
}