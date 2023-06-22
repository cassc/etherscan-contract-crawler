// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../../libraries/Ticket.sol";
import "../logiumBinaryBet/ILogiumBinaryBetCore.sol";

/// @title Trader functionality of LogiumCore
/// @notice functions specified here are executed with msg.sender treated as trader
interface ILogiumCoreTrader {
    /// @notice Emitted when a bet is taken (take ticket is successfully called)
    /// @param issuer issuer/maker of the ticket/offer
    /// @param trader trader/taker of the bet
    /// @param betImplementation address of the bet master contract used
    /// @param takeParams betImplementation dependent take params eg. "fraction" of the ticket to take
    /// @param details betImplementation specific details of the ticket
    event BetEmitted(
        address indexed issuer,
        address indexed trader,
        ILogiumBinaryBetCore betImplementation,
        bytes32 takeParams,
        bytes details
    );

    /// @notice Take a specified amount of the ticket. Emits BetEmitted and CollateralChange events.
    /// @param detailsHash EIP-712 hash of decoded Payload.details. Will be validated
    /// @param payload ticket payload of the ticket to take
    /// @param signature ticket signature of the ticket to take
    /// @param takeParams BetImplementation implementation specific ticket take parameters e.g. amount of bet units to open
    /// @return address of the bet contract.
    /// Note: although after taking the implementation of a bet contract will not change, masterBetContract is subject to change and its interface MAY change
    function takeTicket(
        bytes memory signature,
        Ticket.Payload memory payload,
        bytes32 detailsHash,
        bytes32 takeParams
    ) external returns (address);
}