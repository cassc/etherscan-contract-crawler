// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20UDS} from "UDS/tokens/ERC20UDS.sol";
import {FxBaseRootTunnelUDS} from "./base/FxBaseRootTunnelUDS.sol";

bytes32 constant MINT_ERC20_SIG = keccak256("mintERC20Tokens(address,uint256)");

error InvalidSignature();

abstract contract FxERC20RootUDS is FxBaseRootTunnelUDS, ERC20UDS {
    constructor(address checkpointManager, address fxRoot) FxBaseRootTunnelUDS(checkpointManager, fxRoot) {}

    /* ------------- virtual ------------- */

    function _authorizeTunnelController() internal virtual override;

    /* ------------- external ------------- */

    function lock(address to, uint256 amount) external virtual {
        _burn(msg.sender, amount);

        _sendMessageToChild(abi.encode(MINT_ERC20_SIG, abi.encode(to, amount)));
    }

    function unlock(bytes calldata proofData) external virtual {
        bytes memory message = _validateAndExtractMessage(proofData);

        (bytes32 sig, bytes memory args) = abi.decode(message, (bytes32, bytes));
        (address to, uint256 amount) = abi.decode(args, (address, uint256));

        if (sig != MINT_ERC20_SIG) revert InvalidSignature();

        _mint(to, amount);
    }
}