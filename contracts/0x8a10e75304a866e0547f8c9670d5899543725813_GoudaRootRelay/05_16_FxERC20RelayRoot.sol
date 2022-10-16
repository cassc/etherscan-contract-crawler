// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20UDS} from "UDS/tokens/ERC20UDS.sol";
import {MINT_ERC20_SELECTOR} from "./FxERC20UDSRoot.sol";
import {FxBaseRootTunnel} from "./base/FxBaseRootTunnel.sol";

error TransferFailed();
error InvalidSelector();

/// @title ERC20 Root Tunnel
/// @author phaze (https://github.com/0xPhaze/fx-contracts)
abstract contract FxERC20RelayRoot is FxBaseRootTunnel {
    address public immutable token;

    constructor(
        address erc20Token,
        address checkpointManager,
        address fxRoot
    ) FxBaseRootTunnel(checkpointManager, fxRoot) {
        token = erc20Token;
    }

    /* ------------- virtual ------------- */

    function _authorizeTunnelController() internal virtual override;

    /* ------------- internal ------------- */

    function _mintERC20TokensWithChild(address to, uint256 amount) internal virtual {
        _sendMessageToChild(abi.encodeWithSelector(MINT_ERC20_SELECTOR, to, amount));
    }

    /* ------------- external ------------- */

    /// @dev this assumes a standard ERC20
    /// that throws or returns false on failed transfers
    function lock(address to, uint256 amount) external virtual {
        if (!ERC20UDS(token).transferFrom(msg.sender, address(this), amount)) revert TransferFailed();

        _mintERC20TokensWithChild(to, amount);
    }

    function unlock(bytes calldata proofData) external virtual {
        bytes memory message = _validateAndExtractMessage(proofData);

        (bytes4 selector, address to, uint256 amount) = abi.decode(message, (bytes4, address, uint256));

        if (selector != MINT_ERC20_SELECTOR) revert InvalidSelector();

        if (!ERC20UDS(token).transfer(to, amount)) revert TransferFailed();
    }
}