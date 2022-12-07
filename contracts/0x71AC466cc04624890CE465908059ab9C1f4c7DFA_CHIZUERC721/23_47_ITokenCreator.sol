// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenCreator {
    function tokenCreator(uint256 tokenId)
        external
        view
        returns (address payable);
}