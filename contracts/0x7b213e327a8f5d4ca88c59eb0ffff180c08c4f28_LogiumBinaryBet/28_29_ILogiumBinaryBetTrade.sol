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

/// @title Trade/Take related interface of ILogiumBinaryBet
interface ILogiumBinaryBetTrade {
    /// @notice Emitted on (successful) exercise of a bet/trade
    /// @param id the exercised trade id
    event Exercise(uint256 indexed id);

    /// @notice Exercises own (msg.sender) bet. Requires strike price to be passed and the bet to be in window.
    /// "strike price passed" is defined as: marketTick() >= strike for UP bets or marketTick() <= strike for down bets
    /// "in window" is defined as: expiry - exerciseWindowDuration() < block.timestamp <= expiry where "expiry" is take time + period
    /// @param ticket ticket immutable structure, validated by the contract
    /// @param blockNumber block number of the take to exercise
    function exercise(Ticket.Immutable calldata ticket, uint256 blockNumber)
        external;

    /// @notice Exercises a different party bet. Execution conditions are the same as exercise()
    /// @param ticket ticket immutable structure, validated by the contract
    /// @param id trade/bet id
    /// @param gasFee if extra USDC fee should be taken to reflect gas usage of this call. Set to true by the auto-exercise bot. Should be set to false in other call scenarios.
    function exerciseOther(
        Ticket.Immutable calldata ticket,
        uint256 id,
        bool gasFee
    ) external;

    /// @notice Get tradeId for given trader on given blockNumber
    /// @dev tradeId = trader << 64 | blockNumber
    /// @param trader trader/ticket taker address
    /// @param blockNumber blockNumber of the ticket take transaction
    /// @return tradeId
    function tradeId(address trader, uint256 blockNumber)
        external
        pure
        returns (uint256);
}