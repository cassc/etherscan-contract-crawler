// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenCreator {
    // bytes4(keccak256(tokenCreator(uint256))) == 0x40c1a064
    function tokenCreator(uint256 _tokenId)
        external
        view
        returns (address payable);
}