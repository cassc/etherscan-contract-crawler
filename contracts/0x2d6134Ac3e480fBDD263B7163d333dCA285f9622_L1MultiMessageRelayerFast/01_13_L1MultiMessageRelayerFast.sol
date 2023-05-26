// SPDX-License-Identifier: MIT
pragma solidity >0.7.5;
pragma experimental ABIEncoderV2;

/* Interface Imports */
import { IL1CrossDomainMessengerFast } from "./IL1CrossDomainMessengerFast.sol";

/* Library Imports */
import { Lib_AddressResolver } from "@eth-optimism/contracts/contracts/libraries/resolver/Lib_AddressResolver.sol";

/**
 * @title L1MultiMessageRelayerFast
 * @dev The L1 Multi-Message Relayer Fast contract is a gas efficiency optimization which enables the
 * relayer to submit multiple messages in a single transaction to be relayed by the Fast L1 Cross Domain
 * Message Sender.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract L1MultiMessageRelayerFast is Lib_AddressResolver {

    /***************
     * Structure *
     ***************/

    struct L2ToL1Message {
        address target;
        address sender;
        bytes message;
        uint256 messageNonce;
        IL1CrossDomainMessengerFast.L2MessageInclusionProof proof;
    }

    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Address Manager.
     */
    constructor(
        address _libAddressManager
    )
        Lib_AddressResolver(_libAddressManager)
    {}


    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyBatchRelayer() {
        require(
            msg.sender == resolve("L2BatchFastMessageRelayer"),
            // solhint-disable-next-line max-line-length
            "L1MultiMessageRelayerFast: Function can only be called by the L2BatchFastMessageRelayer"
        );
        _;
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * @notice Forwards multiple cross domain messages to the L1 Cross Domain Messenger Fast for relaying
     * @param _messages An array of L2 to L1 messages
     */
    function batchRelayMessages(
        L2ToL1Message[] calldata _messages
    )
        external
        onlyBatchRelayer
    {
        IL1CrossDomainMessengerFast messenger = IL1CrossDomainMessengerFast(
            resolve("Proxy__L1CrossDomainMessengerFast")
        );

        for (uint256 i = 0; i < _messages.length; i++) {
            L2ToL1Message memory message = _messages[i];
            messenger.relayMessage(
                message.target,
                message.sender,
                message.message,
                message.messageNonce,
                message.proof
            );
        }
    }

    /**
     * @notice Forwards multiple cross domain messages to the L1 Cross Domain Messenger Fast for relaying
     * @param _messages An array of L2 to L1 messages
     * @param _standardBridgeDepositHash current deposit hash of standard bridges
     * @param _lpDepositHash current deposit hash of LP1
     */
    function batchRelayMessages(
        L2ToL1Message[] calldata _messages,
        bytes32 _standardBridgeDepositHash,
        bytes32 _lpDepositHash
    )
        external
        onlyBatchRelayer
    {
        IL1CrossDomainMessengerFast messenger = IL1CrossDomainMessengerFast(
            resolve("Proxy__L1CrossDomainMessengerFast")
        );

        for (uint256 i = 0; i < _messages.length; i++) {
            L2ToL1Message memory message = _messages[i];
            messenger.relayMessage(
                message.target,
                message.sender,
                message.message,
                message.messageNonce,
                message.proof,
                _standardBridgeDepositHash,
                _lpDepositHash
            );
        }
    }
}