//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612Permit {
    /**
     * @dev Sets `_amount` as the allowance of `_spender` over `_owner`'s tokens,
     * given `_owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `_owner` cannot be the zero address.
     * - `_spender` cannot be the zero address.
     * - `_deadline` must be a timestamp in the future.
     * - `_v`, `_r` and `_s` must be a valid `secp256k1` signature from `_owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``_owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address _owner,
        address _spender,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @dev Returns the current ERC2612 nonce for `_owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``_owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address _owner) external view returns (uint256);
}