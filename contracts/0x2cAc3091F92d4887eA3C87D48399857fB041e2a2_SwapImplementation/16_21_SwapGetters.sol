// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SwapState.sol";
import "./SwapStructs.sol";
import "../libraries/external/BytesLib.sol";

/**
 * @title AtlasDexSwap
 */
contract SwapGetters is SwapState {
    using BytesLib for bytes;

    function normalizeAmount(uint256 amount, uint8 decimals) internal pure returns(uint256){
        if (decimals > 8) {
            amount /= 10 ** (decimals - 8);
        }
        return amount;
    }

    function deNormalizeAmount(uint256 amount, uint8 decimals) internal pure returns(uint256){
        if (decimals > 8) {
            amount *= 10 ** (decimals - 8);
        }
        return amount;
    }

    /*
     * @dev Parse a token transfer with payload (payload id 3).
     *
     * @params encoded The byte array corresponding to the token transfer (not
     *                 the whole VAA, only the payload)
     */
    function parseUnlockWithPayload(bytes memory encoded) public pure returns (SwapStructs.CrossChainRelayerPayload memory relayerPayload) {
        uint index = 0;

        relayerPayload.receiver = encoded.toBytes32(index);
        index += 32;

        relayerPayload.token = encoded.toBytes32(index);
        index += 32;

        relayerPayload._id = encoded.toBytes32(index);
        index += 32;

        relayerPayload.slippage = encoded.toUint256(index);
        index += 32;

        relayerPayload.fee = encoded.toUint256(index);
        index += 32;
    }

    function isInitialized(address impl) public view returns (bool) {
        return initializedImplementations[impl];
    }
} // end of class