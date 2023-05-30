// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721M} from "../ERC721M.sol";
import {ERC721MQuery} from "./ERC721MQuery.sol";
import {FxERC721Root} from "fx-contracts/FxERC721Root.sol";

/// @title ERC721M FxPortal extension
/// @author phaze (https://github.com/0xPhaze/ERC721M)
abstract contract FxERC721MRoot is FxERC721Root, ERC721M, ERC721MQuery {
    constructor(
        string memory name,
        string memory symbol,
        address checkpointManager,
        address fxRoot
    ) ERC721M(name, symbol) FxERC721Root(checkpointManager, fxRoot) {}

    /* ------------- virtual ------------- */

    function tokenURI(uint256 id) external view virtual override returns (string memory);

    function _authorizeTunnelController() internal virtual override;

    /* ------------- internal ------------- */

    function _mintLockedAndTransmit(address to, uint256 quantity) internal virtual {
        _mintLockedAndTransmit(to, quantity, 0);
    }

    function _mintLockedAndTransmit(
        address to,
        uint256 quantity,
        uint48 auxData
    ) internal virtual {
        uint256 startId = _nextTokenId();

        _mintAndLock(to, quantity, true, auxData);

        uint256[] memory ids = new uint256[](quantity);

        unchecked {
            for (uint256 i; i < quantity; ++i) {
                ids[i] = startId + i;
            }
        }

        _registerERC721IdsWithChildMem(to, ids);
    }

    function _lockAndTransmit(address from, uint256[] calldata ids) internal virtual {
        unchecked {
            for (uint256 i; i < ids.length; ++i) {
                _lock(from, ids[i]);
            }
        }

        _registerERC721IdsWithChild(from, ids);
    }

    // @notice using `_unlockAndTransmit` is simple and easy
    // this assumes L1 state as the single source of truth
    // messages are always pushed L1 -> L2 without knowing state on L2
    // this means that NFTs should not be allowed to be traded/sold on L2
    // alternatively `_unlockWithProof` should be implemented requiring
    // a MPT inclusion proof.
    function _unlockAndTransmit(address from, uint256[] calldata ids) internal virtual {
        unchecked {
            for (uint256 i; i < ids.length; ++i) _unlock(from, ids[i]);
        }

        _registerERC721IdsWithChild(address(0), ids);
    }
}