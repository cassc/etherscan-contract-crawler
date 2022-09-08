// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBaseRootTunnelUDS} from "./base/FxBaseRootTunnelUDS.sol";

bytes32 constant REGISTER_ERC721s_IDS_SIG = keccak256("registerERC721IdsWithChild(address,address,uint256[])");
bytes32 constant DEREGISTER_ERC721s_IDS_SIG = keccak256("deregisterERC721IdsWithChild(address,uint256[])");

error Disabled();
error InvalidSignature();

/// @title ERC721 FxRootTunnel
/// @author phaze (https://github.com/0xPhaze/fx-contracts)
abstract contract FxERC721sRootTunnelUDS is FxBaseRootTunnelUDS {
    constructor(address checkpointManager, address fxRoot) FxBaseRootTunnelUDS(checkpointManager, fxRoot) {}

    /* ------------- virtual ------------- */

    function _authorizeTunnelController() internal virtual override;

    /* ------------- internal ------------- */

    function _registerERC721IdsWithChild(
        address collection,
        address to,
        uint256[] calldata ids
    ) internal virtual {
        _sendMessageToChild(abi.encode(REGISTER_ERC721s_IDS_SIG, abi.encode(collection, to, ids)));
    }

    function _deregisterERC721IdsWithChild(address collection, uint256[] calldata ids) internal virtual {
        _sendMessageToChild(abi.encode(DEREGISTER_ERC721s_IDS_SIG, abi.encode(collection, ids)));
    }
}