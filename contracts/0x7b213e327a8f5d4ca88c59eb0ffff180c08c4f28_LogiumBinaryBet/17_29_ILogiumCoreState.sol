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

import "../logiumBinaryBet/ILogiumBinaryBetCore.sol";

/// @title Functions for querying the state of the Logium master contract
/// @notice All of these functions are "view". Some directly describe public state variables
interface ILogiumCoreState {
    /// @notice Query all properties stored for a issuer/user
    /// @dev To save gas all user properties fit in a single 256 bit storage slot
    /// @param _0 the queries issuer/user address
    /// @return freeUSDCCollateral free collateral for use with issued tickets
    /// @return invalidation value for ticket invalidation
    /// @return exists whether issuer/user has ever used our protocol
    function users(address _0)
        external
        view
        returns (
            uint128 freeUSDCCollateral,
            uint64 invalidation,
            bool exists
        );

    /// @notice Check if a master bet contract can be used for creating bets
    /// @param betImplementation the address of the contract
    /// @return boolean if it can be used
    function isAllowedBetImplementation(ILogiumBinaryBetCore betImplementation)
        external
        view
        returns (bool);

    /// Get a bet contract for ticket if it exists.
    /// Returned contract is a thin clone of provided logiumBinaryBetImplementation
    /// reverts if the provided logiumBinaryBetImplementation is not allowed
    /// Note: LogiumBinaryBetImplementation may be upgraded/replaced and in the future it
    /// MAY NOT follow ILogiumBinaryBet interface, but it will always follow ILogiumBinaryBetCore interface.
    /// @param hashVal ticket hashVal (do not confuse with ticket hash for signing)
    /// @param logiumBinaryBetImplementation address of bet_implementation of the ticket
    /// @return address of the existing bet contract or 0x0 if the ticket was never taken
    function contractFromTicketHash(
        bytes32 hashVal,
        ILogiumBinaryBetCore logiumBinaryBetImplementation
    ) external view returns (ILogiumBinaryBetCore);
}