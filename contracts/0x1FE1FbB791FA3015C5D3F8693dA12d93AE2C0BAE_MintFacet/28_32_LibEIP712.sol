// SPDX-License-Identifier: MIT
// Forked from OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)
pragma solidity ^0.8.20;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title  LibEIP712
 * @author slvrfn
 * @notice https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 *      The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 *      thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 *      they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 *      This library implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 *      scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 *      ({_hashTypedDataV4}).
 *
 *      The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 *      the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 *      NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 *      https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 *      _Available since v3.4._
 * @dev Updated to allow using Diamond storage pattern, and some managing of signed vouchers
 */
library LibEIP712 {
    using LibEIP712 for LibEIP712.Layout;

    bytes32 internal constant STORAGE_SLOT = keccak256("genesis.libraries.storage.LibEIP712");

    /* solhint-disable var-name-mixedcase */
    struct Layout {
        // Cache the domain separator, but also store the chain id that it corresponds to, in order to
        // invalidate the cached domain separator if the chain id changes.
        bytes32 _CACHED_DOMAIN_SEPARATOR;
        uint256 _CACHED_CHAIN_ID;
        address _CACHED_THIS;
        bytes32 _HASHED_NAME;
        bytes32 _HASHED_VERSION;
        bytes32 _TYPE_HASH;
        mapping(uint256 => uint256) voucherClaimed;
    }

    /* solhint-disable var-name-mixedcase */
    function layout() internal pure returns (Layout storage e) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            e.slot := slot
        }
    }

    function _setup(Layout storage e, bytes32 hashedName, uint256 cachedChainId, address cachedThis, bytes32 typeHash) internal {
        e._HASHED_NAME = hashedName;
        e._CACHED_CHAIN_ID = cachedChainId;
        e._CACHED_THIS = cachedThis;
        e._TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4(Layout storage e) internal view returns (bytes32) {
        if (address(this) == e._CACHED_THIS && block.chainid == e._CACHED_CHAIN_ID) {
            return e._CACHED_DOMAIN_SEPARATOR;
        } else {
            return __buildDomainSeparator(e._TYPE_HASH, e._HASHED_NAME, e._HASHED_VERSION);
        }
    }

    function __buildDomainSeparator(bytes32 typeHash, bytes32 nameHash, bytes32 versionHash) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(Layout storage e, bytes32 structHash) internal view returns (bytes32) {
        return ECDSA.toTypedDataHash(e._domainSeparatorV4(), structHash);
    }

    function _updateVersion(Layout storage e, string memory version) internal returns (bytes32) {
        bytes32 hashedVersion = keccak256(abi.encodePacked(version));
        e._HASHED_VERSION = hashedVersion;
        e._CACHED_DOMAIN_SEPARATOR = __buildDomainSeparator(e._TYPE_HASH, e._HASHED_NAME, hashedVersion);
        return hashedVersion;
    }

    function _hashedVersion(Layout storage e) internal view returns (bytes32) {
        return e._HASHED_VERSION;
    }

    function claimVoucher(Layout storage e, uint256 voucherNonce, uint256 amount) internal {
        // save some gas
        unchecked {
            e.voucherClaimed[voucherNonce] += amount;
        }
    }

    function isVoucherClaimed(Layout storage e, uint256 nonce, uint256 max, uint16 desiredQty) internal view returns (bool) {
        return (e.voucherClaimed[nonce] + desiredQty) > max;
    }

    /// @notice Verifies the digest for a given signature, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to do anything.
    /// @param digest the typed keccak256 digest of some data.
    /// @param signature An ECDSA signature of some data.
    function _verifySignedData(bytes32 digest, bytes memory signature) internal pure returns (address) {
        return ECDSA.recover(digest, signature);
    }
}