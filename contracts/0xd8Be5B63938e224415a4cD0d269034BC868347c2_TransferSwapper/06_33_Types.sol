// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import "./MsgDataTypes.sol";
import "../interfaces/ICodec.sol";

library Types {
    /**
     * @notice Denotes the status of a cross-chain transfer/swap request
     * @dev Partially filled requests are considered 'Succeeded'. There is no 'Failed' state as
     * it's only possible if everything reverts and there is no successful transaction
     * @param Null An empty status that should never be reached
     * @param Succeeded Transfer/swap has succeeded and funds are received by the receiver
     * @param Fallback Swaps have failed on the dst chain, and bridge tokens are refunded to receiver
     */
    enum RequestStatus {
        Null,
        Succeeded,
        Fallback
    }

    struct Request {
        bytes32 id; // see _computeId()
        ICodec.SwapDescription[] swaps; // the swaps need to happen on the destination chain
        address receiver; // see TransferDescription.receiver
        bool nativeOut; // see TransferDescription.nativeOut
        uint256 fee; // see TransferDescription.fee
        bool allowPartialFill; // see TransferDescription.allowPartialFill
        // sets if another cbridge hop is required on the chain, abi.encode(Forward)
        bytes forward;
    }

    struct Forward {
        uint64 dstChain;
        // abi encoded cbridge params
        bytes params;
    }

    struct TransferDescription {
        address receiver; // The receiving party (the user) of the final output token
        uint64 dstChainId; // Destination chain id
        // The address of the TransferSwapper on the destination chain.
        // Ignored if there is no swaps on the destination chain.
        address dstTransferSwapper;
        // A number unique enough to be used in request ID generation.
        uint64 nonce;
        // bridge provider identifier
        string bridgeProvider;
        // Bridge transfers quoted and abi encoded by chainhop backend server.
        // Bridge adapter implementations need to decode this themselves.
        bytes bridgeParams;
        bool nativeIn; // whether to check msg.value and wrap token before swapping/sending
        bool nativeOut; // whether to unwrap before sending the final token to user
        uint256 fee; // this fee is only executor fee. it does not include msg bridge fee
        uint256 feeDeadline; // the unix timestamp before which the fee is valid
        // sig of sha3("executor fee", srcChainId, dstChainId, amountIn, tokenIn, feeDeadline, fee)
        // see _verifyFee()
        bytes feeSig;
        uint256 amountIn;
        address tokenIn;
        address dstTokenOut; // the final output token, emitted in event for display purpose only
        // in case of multi route swaps, whether to allow the successful swaps to go through
        // and sending the amountIn of the failed swaps back to user
        bool allowPartialFill;
        // sets if another cbridge hop is required on the dst chain, abi.encode(Forward)
        bytes forward;
    }
}