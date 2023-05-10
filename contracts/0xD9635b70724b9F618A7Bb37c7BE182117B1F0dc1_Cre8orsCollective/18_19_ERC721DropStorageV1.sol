// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC721Drop} from "../interfaces/IERC721Drop.sol";

/**
 ██████╗██████╗ ███████╗ █████╗  ██████╗ ██████╗ ███████╗
██╔════╝██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔══██╗██╔════╝
██║     ██████╔╝█████╗  ╚█████╔╝██║   ██║██████╔╝███████╗
██║     ██╔══██╗██╔══╝  ██╔══██╗██║   ██║██╔══██╗╚════██║
╚██████╗██║  ██║███████╗╚█████╔╝╚██████╔╝██║  ██║███████║
 ╚═════╝╚═╝  ╚═╝╚══════╝ ╚════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝                                                     
 */

/// @dev origin: https://github.com/ourzora/zora-drops-contracts
contract ERC721DropStorageV1 {
    /// @notice Configuration for NFT minting contract storage
    IERC721Drop.Configuration public config;

    /// @notice Sales configuration
    IERC721Drop.SalesConfiguration public salesConfig;

    /// @notice Burn configuration
    IERC721Drop.BurnConfiguration public burnConfig;

    /// @dev Mapping for presale mint counts by address to allow public mint limit
    mapping(address => uint256) public presaleMintsByAddress;
}