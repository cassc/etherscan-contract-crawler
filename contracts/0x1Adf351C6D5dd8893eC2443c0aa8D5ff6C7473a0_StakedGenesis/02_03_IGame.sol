// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGame {
    function genesisType(uint16 nft) external view returns (uint8);
}