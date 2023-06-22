// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IChainsTraits {
    function traitTypes(uint256 i, uint256 j)
        external
        view
        returns (string memory,string memory,string memory,uint256);
}