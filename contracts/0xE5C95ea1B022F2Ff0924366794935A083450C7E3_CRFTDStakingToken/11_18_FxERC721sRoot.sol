// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBaseRootTunnel} from "./base/FxBaseRootTunnel.sol";

bytes4 constant REGISTER_ERC721s_IDS_SELECTOR =
    bytes4(keccak256("registerERC721IdsWithChild(address,address,uint256[])"));

/// @title ERC721 FxRootTunnel
/// @author phaze (https://github.com/0xPhaze/fx-contracts)
abstract contract FxERC721sRoot is FxBaseRootTunnel {
    constructor(address checkpointManager, address fxRoot) FxBaseRootTunnel(checkpointManager, fxRoot) {}

    /* ------------- virtual ------------- */

    function _authorizeTunnelController() internal virtual override;

    /* ------------- internal ------------- */

    function _registerERC721IdsWithChild(address collection, address to, uint256[] calldata ids) internal virtual {
        _sendMessageToChild(abi.encodeWithSelector(REGISTER_ERC721s_IDS_SELECTOR, collection, to, ids));
    }
}