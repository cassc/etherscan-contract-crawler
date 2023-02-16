// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IKitsERC721Drop} from "../../interfaces/IKitsERC721Drop.sol";

contract ERC721DropStorageV1 {
    /// @notice Configuration for NFT minting contract storage
    IKitsERC721Drop.Configuration public config;

    /// @notice Sales configuration
    IKitsERC721Drop.SalesConfiguration public salesConfig;

    /// @dev Number of total presale mints. Includes merkle root mints plus allowlist mints
    uint256 public presaleMints;

    /// @dev Mapping for presale mint counts by address
    mapping(address => uint256) public presaleMintsByAddress;

    /// @dev HTTP URI, up to but not including, the contract address. eg: https://arpeggi.io/api/v2/kits-metadata
    string baseURI;
}