// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20UDS} from "UDS/tokens/ERC20UDS.sol";
import {FxBaseRootTunnel} from "./base/FxBaseRootTunnel.sol";

bytes4 constant MINT_ERC20_SELECTOR = bytes4(keccak256("mintERC20Tokens(address,uint256)"));

error InvalidSelector();

/// @title ERC20 Root
/// @author phaze (https://github.com/0xPhaze/fx-contracts)
abstract contract FxERC20UDSRoot is FxBaseRootTunnel, ERC20UDS {
    constructor(address checkpointManager, address fxRoot) FxBaseRootTunnel(checkpointManager, fxRoot) {}

    /* ------------- virtual ------------- */

    function _authorizeTunnelController() internal virtual override;

    /* ------------- internal ------------- */

    function _mintERC20TokensWithChild(address to, uint256 amount) internal virtual {
        _sendMessageToChild(abi.encodeWithSelector(MINT_ERC20_SELECTOR, to, amount));
    }

    /* ------------- external ------------- */

    function lock(address to, uint256 amount) external virtual {
        _burn(msg.sender, amount);

        _mintERC20TokensWithChild(to, amount);
    }

    function unlock(bytes calldata proofData) external virtual {
        bytes memory message = _validateAndExtractMessage(proofData);

        (bytes4 selector, address to, uint256 amount) = abi.decode(message, (bytes4, address, uint256));

        if (selector != MINT_ERC20_SELECTOR) revert InvalidSelector();

        _mint(to, amount);
    }
}