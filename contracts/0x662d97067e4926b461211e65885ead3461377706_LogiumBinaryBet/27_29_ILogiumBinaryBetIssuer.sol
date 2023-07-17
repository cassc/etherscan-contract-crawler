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

/// @title Issuer functionality of LogiumBinaryBet
interface ILogiumBinaryBetIssuer {
    /// @notice Emitted on claim
    event Claim();

    /// @notice Transfer all issuer winnings to the issuer. Requires that all traders' bets have expired
    /// This function can be called by anyone, but the profit will always be sent to the issuer address
    /// @param ticket ticket immutable structure, validated by the contract
    function claim(Ticket.Immutable calldata ticket) external;

    /// @notice Check expiry of the last trade/take, profits can only be claimed after the returned time
    /// @return expiry of the last trade in block.timestamp (secs since epoch)
    function claimableFrom() external returns (uint256);
}