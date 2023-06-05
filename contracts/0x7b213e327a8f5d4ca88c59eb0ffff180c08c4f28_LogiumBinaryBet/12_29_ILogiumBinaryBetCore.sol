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

/// @title Bet interface required by the Logium master contract
/// @notice All non view functions here can only be called by LogiumCore
interface ILogiumBinaryBetCore {
    /// @notice Initialization function. Initializes AND issues a bet. Will be called by the master contract once on only the first take of a given bet instance.
    /// Master MUST transfer returned collaterals or revert.
    /// @param detailsHash expected EIP-712 hash of decoded details implementation must validate this hash
    /// @param trader trader address for the issuing bet
    /// @param takeParams BetImplementation implementation specific ticket take parameters e.g. amount of bet units to open
    /// @param volume total ticket volume, BetImplementation implementation should check issuer volume will not be exceeded
    /// @param detailsEnc BetImplementation implementation specific ticket details
    /// @return issuerPrice issuer USDC collateral expected
    /// @return traderPrice trader USDC collateral expected
    function initAndIssue(
        bytes32 detailsHash,
        address trader,
        bytes32 takeParams,
        uint128 volume,
        bytes calldata detailsEnc
    ) external returns (uint256 issuerPrice, uint256 traderPrice);

    /// @notice Issue a bet to a trader. Master will transfer returned collaterals or revert.
    /// @param detailsHash expected EIP-712 hash of decoded details implementation must validate this hash
    /// @param trader trader address
    /// @param takeParams BetImplementation implementation specific ticket take parameters eg. amount of bet units to open
    /// @param volume total ticket volume, BetImplementation implementation should check issuer volume will not be exceeded
    /// @param detailsEnc BetImplementation implementation specific ticket details
    /// @return issuerPrice issuer USDC collateral expected
    /// @return traderPrice trader USDC collateral expected
    function issue(
        bytes32 detailsHash,
        address trader,
        bytes32 takeParams,
        uint128 volume,
        bytes calldata detailsEnc
    ) external returns (uint256 issuerPrice, uint256 traderPrice);

    /// @notice Query total issuer used volume
    /// @return the total USDC usage
    function issuerTotal() external view returns (uint256);

    /// @notice EIP712 type string of decoded details
    /// @dev used by Core for calculation of Ticket type hash
    /// @return the details type, must contain a definition of "Details"
    // solhint-disable-next-line func-name-mixedcase
    function DETAILS_TYPE() external pure returns (bytes memory);
}