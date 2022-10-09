// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { ICurator } from "./interfaces/ICurator.sol";
import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { IMetadataRenderer } from "./interfaces/IMetadataRenderer.sol";


/**
 @notice Curator storage variables contract.
 @author [email protected]
 */
abstract contract CuratorStorageV1 is ICurator {
    /// @notice Standard ERC721 name for the contract
    string internal contractName;

    /// @notice Standard ERC721 symbol for the curator contract
    string internal contractSymbol;

    /// Curation pass as an ERC721 that allows other users to curate.
    /// @notice Address to ERC721 with `balanceOf` function.
    IERC721Upgradeable public curationPass;

    /// Stores virtual mapping array length parameters
    /// @notice Array total size (total size)
    uint40 public numAdded;

    /// @notice Array active size = numAdded - numRemoved
    /// @dev Blank entries are retained within array
    uint40 public numRemoved;

    /// @notice If curation is paused by the owner
    bool public isPaused;

    /// @notice timestamp that the curation is frozen at (if never, frozen = 0)
    uint256 public frozenAt;

    /// @notice Limit of # of items that can be curated
    uint256 public curationLimit;

    /// @notice Address of the NFT Metadata renderer contract
    IMetadataRenderer public renderer;

    /// @notice Listing id => Listing struct mapping, listing IDs are 0 => upwards
    /// @dev Can contain blank entries (not garbage compacted!)
    mapping(uint256 => Listing) public idToListing;

    /// @notice Storage gap
    uint256[49] __gap;
}