// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "sol.lib.memory/LibUint256Array.sol";
import "rain.lib.hash/LibHashNoAlloc.sol";

import {SignatureChecker} from "openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import "./IInterpreterCallerV2.sol";

/// Thrown when the ith signature from a list of signed contexts is invalid.
error InvalidSignature(uint256 i);

/// @title LibContext
/// @notice Conventions for working with context as a calling contract. All of
/// this functionality is OPTIONAL but probably useful for the majority of use
/// cases. By building and authenticating onchain, caller provided and signed
/// contexts all in a standard way the overall usability of context is greatly
/// improved for expression authors and readers. Any calling contract that can
/// match the context expectations of an existing expression is one large step
/// closer to compatibility and portability, inheriting network effects of what
/// has already been authored elsewhere.
library LibContext {
    using LibUint256Array for uint256[];

    /// The base context is the `msg.sender` and address of the calling contract.
    /// As the interpreter itself is called via an external interface and may be
    /// statically calling itself, it MAY NOT have any ability to inspect either
    /// of these values. Even if this were not the case the calling contract
    /// cannot assume the existence of some opcode(s) in the interpreter that
    /// inspect the caller, so providing these two values as context is
    /// sufficient to decouple the calling contract from the interpreter. It is
    /// STRONGLY RECOMMENDED that even if the calling contract has "no context"
    /// that it still provides this base to every `eval`.
    ///
    /// Calling contracts DO NOT need to call this directly. It is built and
    /// merged automatically into the standard context built by `build`.
    ///
    /// @return The `msg.sender` and address of the calling contract using this
    /// library, as a context-compatible array.
    function base() internal view returns (uint256[] memory) {
        return LibUint256Array.arrayFrom(uint256(uint160(msg.sender)), uint256(uint160(address(this))));
    }

    function hash(SignedContextV1 memory signedContext_) internal pure returns (bytes32 hash_) {
        uint256 signerOffset_ = SIGNED_CONTEXT_SIGNER_OFFSET;
        uint256 contextOffset_ = SIGNED_CONTEXT_CONTEXT_OFFSET;
        uint256 signatureOffset_ = SIGNED_CONTEXT_SIGNATURE_OFFSET;

        assembly ("memory-safe") {
            mstore(0, keccak256(add(signedContext_, signerOffset_), 0x20))

            let context_ := mload(add(signedContext_, contextOffset_))
            mstore(0x20, keccak256(add(context_, 0x20), mul(mload(context_), 0x20)))

            mstore(0, keccak256(0, 0x40))

            let signature_ := mload(add(signedContext_, signatureOffset_))
            mstore(0x20, keccak256(add(signature_, 0x20), mload(signature_)))

            hash_ := keccak256(0, 0x40)
        }
    }

    /// Standard hashing process over a list of signed contexts. Situationally
    /// useful if the calling contract wants to record that it has seen a set of
    /// signed data then later compare it against some input (e.g. to ensure that
    /// many calls of some function all share the same input values). Note that
    /// unlike the internals of `build`, this hashes over the signer and the
    /// signature, to ensure that some data cannot be re-signed and used under
    /// a different provenance later.
    /// @param signedContexts_ The list of signed contexts to hash over.
    /// @return hash_ The hash of the signed contexts.
    function hash(SignedContextV1[] memory signedContexts_) internal pure returns (bytes32 hash_) {
        uint256 cursor_;
        uint256 end_;
        bytes32 hashNil_ = HASH_NIL;
        assembly ("memory-safe") {
            cursor_ := add(signedContexts_, 0x20)
            end_ := add(cursor_, mul(mload(signedContexts_), 0x20))
            mstore(0, hashNil_)
        }

        SignedContextV1 memory signedContext_;
        bytes32 mem0_;
        while (cursor_ < end_) {
            assembly ("memory-safe") {
                signedContext_ := mload(cursor_)
                // Subhash will write to 0 for its own hashing so keep a copy
                // before it gets overwritten.
                mem0_ := mload(0)
            }
            bytes32 subHash_ = hash(signedContext_);
            assembly ("memory-safe") {
                mstore(0, mem0_)
                mstore(0x20, subHash_)
                mstore(0, keccak256(0, 0x40))
                cursor_ := add(cursor_, 0x20)
            }
        }
        assembly ("memory-safe") {
            hash_ := mload(0)
        }
    }

    /// Builds a standard 2-dimensional context array from base, calling and
    /// signed contexts. Note that "columns" of a context array refer to each
    /// `uint256[]` and each item within a `uint256[]` is a "row".
    ///
    /// @param baseContext_ Anything the calling contract can provide which MAY
    /// include input from the `msg.sender` of the calling contract. The default
    /// base context from `LibContext.base()` DOES NOT need to be provided by the
    /// caller, this matrix MAY be empty and will be simply merged into the final
    /// context. The base context matrix MUST contain a consistent number of
    /// columns from the calling contract so that the expression can always
    /// predict how many unsigned columns there will be when it runs.
    /// @param signedContexts_ Signed contexts are provided by the `msg.sender`
    /// but signed by a third party. The expression (author) defines _who_ may
    /// sign and the calling contract authenticates the signature over the
    /// signed data. Technically `build` handles all the authentication inline
    /// for the calling contract so if some context builds it can be treated as
    /// authentic. The builder WILL REVERT if any of the signatures are invalid.
    /// Note two things about the structure of the final built context re: signed
    /// contexts:
    /// - The first column is a list of the signers in order of what they signed
    /// - The `msg.sender` can provide an arbitrary number of signed contexts so
    ///   expressions DO NOT know exactly how many columns there are.
    /// The expression is responsible for defining e.g. a domain separator in a
    /// position that would force signed context to be provided in the "correct"
    /// order, rather than relying on the `msg.sender` to honestly present data
    /// in any particular structure/order.
    function build(uint256[][] memory baseContext_, SignedContextV1[] memory signedContexts_)
        internal
        view
        returns (uint256[][] memory)
    {
        unchecked {
            uint256[] memory signers_ = new uint256[](signedContexts_.length);

            // - LibContext.base() + whatever we are provided.
            // - signed contexts + signers if they exist else nothing.
            uint256 contextLength_ =
                1 + baseContext_.length + (signedContexts_.length > 0 ? signedContexts_.length + 1 : 0);

            uint256[][] memory context_ = new uint256[][](contextLength_);
            uint256 offset_ = 0;
            context_[offset_] = LibContext.base();

            for (uint256 i_ = 0; i_ < baseContext_.length; i_++) {
                offset_++;
                context_[offset_] = baseContext_[i_];
            }

            if (signedContexts_.length > 0) {
                offset_++;
                context_[offset_] = signers_;

                for (uint256 i_ = 0; i_ < signedContexts_.length; i_++) {
                    if (
                        // Unlike `LibContext.hash` we can only hash over
                        // the context as it's impossible for a signature
                        // to sign itself.
                        // Note the use of encodePacked here over a
                        // single array, not including the length. This
                        // would be a security issue if multiple dynamic
                        // length values were hashed over together as
                        // then many possible inputs could collide with
                        // a single encoded output.
                        !SignatureChecker.isValidSignatureNow(
                            signedContexts_[i_].signer,
                            ECDSA.toEthSignedMessageHash(LibHashNoAlloc.hashWords(signedContexts_[i_].context)),
                            signedContexts_[i_].signature
                        )
                    ) {
                        revert InvalidSignature(i_);
                    }

                    signers_[i_] = uint256(uint160(signedContexts_[i_].signer));
                    offset_++;
                    context_[offset_] = signedContexts_[i_].context;
                }
            }

            return context_;
        }
    }
}