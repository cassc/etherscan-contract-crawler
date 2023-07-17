// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import {IWormhole} from "../interfaces/IWormhole.sol";

contract CircleRelayerStorage {
    struct State {
        // Wormhole chain ID of this contract
        uint16 chainId;

        // decimals of the native token on this chain
        uint8 nativeTokenDecimals;

        // If true, token transfer requests are blocked.
        bool paused;

        // owner of this contract
        address owner;

        // intermediate state when transfering contract ownership
        address pendingOwner;

        // address that can update swap rates and relayer fees
        address ownerAssistant;

        // recipient of relayer fees
        address feeRecipient;

        // address of the Wormhole contract on this chain
        address wormhole;

        // address of the trusted Circle Integration contract on this chain
        address circleIntegration;

        // precision of the nativeSwapRates, this value should NEVER be set to zero
        uint256 nativeSwapRatePrecision;

        // mapping of chainId to source token address to relayerFee
        mapping(uint16 => mapping(address => uint256)) relayerFees;

        /**
         * Mapping of source token address to native asset swap rate
         * (nativePriceUSD/tokenPriceUSD).
         */
        mapping(address => uint256) nativeSwapRates;

        /**
         * Mapping of source token address to maximum native asset swap amount
         * allowed.
         */
        mapping(address => uint256) maxNativeSwapAmount;

        // Wormhole chain ID to registered contract address mapping
        mapping(uint16 => bytes32) registeredContracts;
    }
}

contract CircleRelayerState {
    CircleRelayerStorage.State _state;
}