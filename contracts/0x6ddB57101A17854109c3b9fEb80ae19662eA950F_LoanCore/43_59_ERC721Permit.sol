// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./interfaces/IERC721Permit.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import { ERC721P_DeadlineExpired, ERC721P_NotTokenOwner, ERC721P_InvalidSignature } from "./errors/LendingUtils.sol";

/**
 * @title ERC721Permit
 * @author Non-Fungible Technologies, Inc.
 *
 * @dev Implementation of the ERC721 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/draft-EIP712.sol
 *
 * Adds the {permit} method, which can be used to change an account's ERC721 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC721-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC721Permit is ERC721, IERC721Permit, EIP712 {
    using Counters for Counters.Counter;

    // ============================================ STATE ==============================================

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");

    /// @dev Nonce for permit signatures.
    mapping(address => Counters.Counter) private _nonces;

    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC721 token name.
     *
     * @param name                  The name of the signing domain.
     */
    constructor(string memory name) EIP712(name, "1") {}

    // ===================================== PERMIT FUNCTIONALITY =======================================

    /**
     * @notice Allows the spender to spend the token ID which is owned by owner,
     * given owner's signed approval.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `owner` must be the owner of `tokenId`.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * @param owner                 The owner of the token being permitted.
     * @param spender               The address allowed to spend the token.
     * @param tokenId               The token ID of the given asset.
     * @param deadline              The maximum timestamp the signature is valid for.
     * @param v                     Component of the signature.
     * @param r                     Component of the signature.
     * @param s                     Component of the signature.
     */
    function permit(
        address owner,
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        if (block.timestamp > deadline) revert ERC721P_DeadlineExpired(deadline);
        if (owner != ERC721.ownerOf(tokenId)) revert ERC721P_NotTokenOwner(owner);

        bytes32 structHash = keccak256(
            abi.encode(_PERMIT_TYPEHASH, owner, spender, tokenId, _useNonce(owner), deadline)
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) revert ERC721P_InvalidSignature(signer);

        _approve(spender, tokenId);
    }

    /**
     * @notice Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated.
     *
     * Every successful call to permit increases the owner's nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * @param owner                 The given owner to check the nonce for.
     *
     * @return current              The current noonce for the owner.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @notice Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     *
     * @return separator             The bytes for the domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev Consumes the nonce - returns the current value and increments.
     *
     * @param owner                 The address of the user to consume a nonce for.
     *
     * @return current              The current nonce, before incrementation.
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}