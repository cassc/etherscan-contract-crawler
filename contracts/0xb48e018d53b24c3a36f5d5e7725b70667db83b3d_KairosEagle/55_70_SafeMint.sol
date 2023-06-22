// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {NFTUtils} from "./NFTUtils.sol";
import {Provision, SupplyPosition} from "../DataStructure/Storage.sol";
import {supplyPositionStorage} from "../DataStructure/Global.sol";

/// @notice safeMint internal method added to base ERC721 implementation for supply position minting
/// @dev inherit this to make an ERC721-compliant facet with added feature internal safeMint
contract SafeMint is NFTUtils {
    /// @notice mints a new supply position to `to`
    /// @param to receiver of the position
    /// @param provision metadata of the supply position
    /// @return tokenId identifier of the supply position
    function safeMint(address to, Provision memory provision) internal returns (uint256 tokenId) {
        SupplyPosition storage sp = supplyPositionStorage();

        tokenId = ++sp.totalSupply;
        sp.provision[tokenId] = provision;
        _safeMint(to, tokenId);
    }

    /* solhint-disable no-empty-blocks */
    function emitTransfer(address from, address to, uint256 tokenId) internal virtual override {}

    function emitApproval(address owner, address approved, uint256 tokenId) internal virtual override {}

    function emitApprovalForAll(address owner, address operator, bool approved) internal virtual override {}
}