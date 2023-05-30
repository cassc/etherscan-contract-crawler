// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBaseRootTunnel} from "./base/FxBaseRootTunnel.sol";

bytes4 constant REGISTER_ERC721_IDS_SELECTOR = bytes4(keccak256("registerERC721IdsWithChild(address,uint256[])"));
bytes4 constant DEREGISTER_ERC721_IDS_SELECTOR = bytes4(keccak256("deregisterERC721IdsWithChild(uint256[])"));

/// @title ERC721 FxRootTunnel
/// @author phaze (https://github.com/0xPhaze/fx-contracts)
abstract contract FxERC721Root is FxBaseRootTunnel {
    constructor(address checkpointManager, address fxRoot) FxBaseRootTunnel(checkpointManager, fxRoot) {}

    /* ------------- virtual ------------- */

    function _authorizeTunnelController() internal virtual override;

    /* ------------- internal ------------- */

    function _registerERC721IdsWithChild(address to, uint256[] calldata ids) internal virtual {
        _sendMessageToChild(abi.encodeWithSelector(REGISTER_ERC721_IDS_SELECTOR, to, ids));
    }

    function _registerERC721IdsWithChildMem(address to, uint256[] memory ids) internal virtual {
        _sendMessageToChild(abi.encodeWithSelector(REGISTER_ERC721_IDS_SELECTOR, to, ids));
    }
}