// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./AdapterBase.sol";
import "../interfaces/external/IWormhole.sol";

contract WormholeAdapter is AdapterBase {
    /// @notice Adapter constructor
    /// @param target_ Target contract for this adapter
    constructor(address target_) AdapterBase(target_) {}

    struct TransferArgs {
        uint16 recipientChain;
        bytes32 recipient;
        uint256 arbiterFee;
        uint32 nonce;
    }

    /// @inheritdoc AdapterBase
    function _executeCall(
        address tokenIn,
        uint256 amountIn,
        bytes memory args
    ) internal override {
        if (amountIn == 0) {
            // Claim from Wormhole bridge
            IWormhole(target).completeTransfer(args);
            return;
        }

        TransferArgs memory transferArgs = abi.decode(args, (TransferArgs));
        if (tokenIn == address(0)) {
            // Wrap and transfer ETH
            IWormhole(target).wrapAndTransferETH{value: amountIn}(
                transferArgs.recipientChain,
                transferArgs.recipient,
                transferArgs.arbiterFee,
                transferArgs.nonce
            );
        } else {
            // Transfer ERC-20 tken
            IWormhole(target).transferTokens(
                tokenIn,
                amountIn,
                transferArgs.recipientChain,
                transferArgs.recipient,
                transferArgs.arbiterFee,
                transferArgs.nonce
            );
        }
    }
}