// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title Interface for FlavorInfo objects.
 */
interface IFlavorInfo {
    struct FlavorInfo {
        uint64 flavorId;
        uint64 price;
        uint64 maxSupply;
        uint64 totalMinted;
        string uriFragment;
    }
}