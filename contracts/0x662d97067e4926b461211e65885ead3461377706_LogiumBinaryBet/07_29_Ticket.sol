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

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/logiumBinaryBet/ILogiumBinaryBetCore.sol";

/// @title Ticket library with structure and helper functions
/// @notice allows calculation of ticket properties and validation of an ticket
/// @dev It's recommended to use all of this function throw `using Ticket for Ticket.Payload;`
library Ticket {
    using ECDSA for bytes32;
    using Ticket for Payload;

    /// Ticket structure as signed by issuer
    /// Ticket parameters:
    /// - nonce - ticket is only valid for taking if nonce > user.invalidation
    /// - deadline - unix secs timestamp, ticket is only valid for taking if blocktime is < deadline
    /// - volume - max issuer collateral allowed to be used by this ticket
    /// - betImplementation - betImplementation that's code will govern this ticket
    /// - details - extra ticket parameters interpreted by betImplementation
    struct Payload {
        uint128 volume;
        uint64 nonce;
        uint256 deadline;
        ILogiumBinaryBetCore betImplementation;
        bytes details;
    }

    /// Structure with ticket properties that affect hashVal
    struct Immutable {
        address maker;
        bytes details;
    }

    /// @notice Calculates hashVal of a maker's ticket. For each unique HashVal only one BetContract is created.
    /// Nonce, volume, deadline or betImplementation do not affect the hashVal. Ticket "details" and signer (signing by a different party) do.
    /// @param self details
    /// @param maker the maker/issuer address
    /// @return the hashVal
    function hashVal(bytes memory self, address maker)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(maker, self));
    }

    function hashValImmutable(Immutable memory self)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(self.maker, self.details));
    }

    function fullTypeHash(bytes memory detailsType)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                bytes.concat(
                    "Ticket(uint128 volume,uint64 nonce,uint256 deadline,address betImplementation,Details details)",
                    detailsType
                )
            );
    }
}