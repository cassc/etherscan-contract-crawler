//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

/**
 * @title  Atomic approve token
 * @author ysqi
 * @notice gives permission to transfer token to another account on this call.
 */
interface IApproveAuthorization {
    /**
     * @notice the `from` gives permission to `to` to transfer token to another account on this call.
     * The approval is cleared when the call is end.
     *
     * Emits an `AtomicApproved` event.
     *
     * Requirements:
     *
     * - `to` must be the same with `msg.sender`. and it must implement {IApproveSet-onAtomicApproveSet}, which is called after approve.
     * - `to` can't be the `from`.
     * - `nonce` can only be used once.
     * - The validity of this authorization operation must be between `validAfter` and `validBefore`.
     *
     * @param from        from's address (Authorizer)
     * @param to      to's address
     * @param validAfter    The time after which this is valid (unix time)
     * @param validBefore   The time before which this is valid (unix time)
     * @param salt          Unique salt
     * @param signature     the signature
     */
    function approveForAllAuthorization(
        address from,
        address to,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 salt,
        bytes memory signature
    ) external;
}