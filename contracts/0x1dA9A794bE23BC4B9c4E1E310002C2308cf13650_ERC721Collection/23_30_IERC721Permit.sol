// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

/**
 * @dev Interface of the ERC1155 Permit extension allowing approvals to be made via signatures,
 * similar to defined for ERC20 in https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 */
interface IERC721Permit {
    /**
     * @dev Sets approval of `to` over owner's token with ``tokenId`` id,
     * given owner's signed approval.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `signature` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address to, uint256 tokenId, uint256 deadline, bytes calldata signature) external;

    /**
     * @dev Sets `approved` as the allowance of `operator` over ``owner``'s all tokens,
     * given ``owner``'s signed approval.
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `signature` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permitForAll(
        address owner,
        address operator,
        bool approved,
        uint256 deadline,
        bytes calldata signature
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}