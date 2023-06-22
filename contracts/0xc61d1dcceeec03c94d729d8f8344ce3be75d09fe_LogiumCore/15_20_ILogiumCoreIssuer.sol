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

/// @title Issuer functionality of LogiumCore
/// @notice functions specified here are executed with msg.sender treated as issuer
interface ILogiumCoreIssuer {
    /// Structure signed by an issuer that authorizes another account to withdraw all free collateral
    /// - to - the address authorized to withdraw
    /// - expiry - timestamp of authorization expiry
    struct WithdrawAuthorization {
        address to;
        uint256 expiry;
    }

    /// Structure signed by an issuer that allows delegated invalidation increase
    struct InvalidationMessage {
        uint64 newInvalidation;
    }

    /// @notice emitted on any free collateral change (deposit, withdraw and takeTicket)
    /// @param issuer issuer address whose free collateral is changing
    /// @param change the change to free collateral positive on deposit, negative on withdrawal and takeTicket
    event CollateralChange(address indexed issuer, int128 change);

    /// @notice emitted on change of invalidation value
    /// @param issuer issuer address who changed their invalidation value
    /// @param newValue new invalidation value
    event Invalidation(address indexed issuer, uint64 newValue);

    /// @notice Withdraw caller USDC from free collateral
    /// @param amount to withdraw. Reverts if amount exceeds balance.
    function withdraw(uint128 amount) external;

    /// @notice Withdraw all caller USDC from free collateral
    /// @return _0 amount actually withdrawn
    function withdrawAll() external returns (uint256);

    /// @notice Withdraw free collateral from another issuer to the caller
    /// @param amount to withdraw. Reverts if amount exceeds balance.
    /// @param authorization authorization created and signed by the other account
    /// @param signature signature of authorization by the from account
    /// @return _0 recovered address of issuer account
    function withdrawFrom(
        uint128 amount,
        WithdrawAuthorization calldata authorization,
        bytes calldata signature
    ) external returns (address);

    /// @notice Withdraw all from other issuer account freeCollateral USDC to caller address
    /// @param authorization authorization created and signed by the other account
    /// @param signature signature of authorization by the from account
    /// @return _0 recovered address of issuer account
    /// @return _1 amount actually withdrawn
    function withdrawAllFrom(
        WithdrawAuthorization calldata authorization,
        bytes calldata signature
    ) external returns (address, uint256);

    /// @notice Deposit caller USDC to free collateral. Requires approval on USDC contract
    /// @param amount amount to deposit
    function deposit(uint128 amount) external;

    /// @notice Deposit from sender to target user freeCollateral
    /// @param target target address for freeCollateral deposit
    /// @param amount amount to deposit
    function depositTo(address target, uint128 amount) external;

    /// @notice Change caller invalidation value. Invalidation value can be only increased
    /// @param newInvalidation new invalidation value
    function invalidate(uint64 newInvalidation) external;

    /// @notice Change other issuer invalidation value using an invalidation message signed by them. Invalidation value can be only increased
    /// @param invalidationMsg the invalidation message containing new invalidation value
    /// @param signature issuer signature over invalidation message
    function invalidateOther(
        InvalidationMessage calldata invalidationMsg,
        bytes calldata signature
    ) external;
}