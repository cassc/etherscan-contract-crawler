// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

interface ITokenUriSupplier {
    function tokenURI(uint256 tokenId)
        external
        view
        returns (string memory);
}