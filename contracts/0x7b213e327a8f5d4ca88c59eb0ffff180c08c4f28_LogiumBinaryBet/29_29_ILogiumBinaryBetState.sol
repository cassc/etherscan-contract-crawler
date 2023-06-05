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

/// @title State of a LogiumBinaryBet
/// @notice view functions exposing LogiumBinaryBet state, may not be available in other types of bets
interface ILogiumBinaryBetState {
    /// @notice Query details of a trade. Empty after the trade is exercised
    /// @param _0 the tradeId
    /// @return amount trade/bet amount in smallest units as described by the RatioMath library
    /// @return end expiry of the trade/bet
    function traders(uint256 _0)
        external
        view
        returns (uint128 amount, uint128 end);

    /// @notice Query total stake of the issuer. Note: returned value DOES NOT take into account any "exercised" bets, it's only a total of deposited collateral.
    /// @return the total USDC stake value
    function issuerTotal() external view returns (uint256);

    /// @notice Query all traders total stake. Note: returned value DOES NOT take into account any "exercised" bets, it's only a total of deposited collateral.
    /// @param ticket ticket immutable structure, validated by the contract
    /// @return the total USDC stake value
    function tradersTotal(Ticket.Immutable calldata ticket)
        external
        view
        returns (uint256);

    /// @notice current marketTick as used for determining passing strikePrice. Uses Market library.
    /// @param ticket ticket immutable structure, validated by the contract
    /// @return tick = log_1.0001(asset_price_in_usdc)
    function marketTick(Ticket.Immutable calldata ticket)
        external
        view
        returns (int24);

    /// @notice Provides bet exercisability window size
    /// @return exercise window duration in secs
    /// @param ticket ticket immutable structure, validated by the contract
    function exerciseWindowDuration(Ticket.Immutable calldata ticket)
        external
        view
        returns (uint256);
}