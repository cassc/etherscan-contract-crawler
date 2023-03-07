// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity 0.8.14;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { LowLevelHelpers } from "./LowLevelHelpers.sol";

import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { OrderTypes } from "../libs/OrderTypes.sol";
import { EIP2098_allButHighestBitMask, OneWord, OneWordShift, BulkOrder_Typehash_Height_One, BulkOrder_Typehash_Height_Two, BulkOrder_Typehash_Height_Three, BulkOrder_Typehash_Height_Four, BulkOrder_Typehash_Height_Five, BulkOrder_Typehash_Height_Six, BulkOrder_Typehash_Height_Seven, BulkOrder_Typehash_Height_Eight, BulkOrder_Typehash_Height_Nine, BulkOrder_Typehash_Height_Ten, BulkOrder_Typehash_Height_Eleven, BulkOrder_Typehash_Height_Twelve, BulkOrder_Typehash_Height_Thirteen, BulkOrder_Typehash_Height_Fourteen, BulkOrder_Typehash_Height_Fifteen, BulkOrder_Typehash_Height_Sixteen, BulkOrder_Typehash_Height_Seventeen, BulkOrder_Typehash_Height_Eighteen, BulkOrder_Typehash_Height_Nineteen, BulkOrder_Typehash_Height_Twenty, BulkOrder_Typehash_Height_TwentyOne, BulkOrder_Typehash_Height_TwentyTwo, BulkOrder_Typehash_Height_TwentyThree, BulkOrder_Typehash_Height_TwentyFour } from "./Constants.sol";

/**
 * @title SignatureChecker
 * @notice This contract allows verification of signatures for both EOAs and contracts
 */
contract SignatureChecker is LowLevelHelpers {
    /**
     * @dev Revert with an error when a signature that does not contain a v
     *      value of 27 or 28 has been supplied.
     *
     * @param v The invalid v value.
     */
    error BadSignatureV(uint8 v);

    /**
     * @dev Revert with an error when the signer recovered by the supplied
     *      signature does not match the offerer or an allowed EIP-1271 signer
     *      as specified by the offerer in the event they are a contract.
     */
    error InvalidSigner();

    /**
     * @dev Revert with an error when a signer cannot be recovered from the
     *      supplied signature.
     */
    error InvalidSignature();

    /**
     * @dev Revert with an error when an EIP-1271 call to an account fails.
     */
    error BadContractSignature();

    /**
     * @notice Returns whether the signer matches the signed message
     * @param orderHash the hash containing the signed message
     * @param signer the signer address to confirm message validity
     * @param sig the signature
     * @param domainSeparator parameter to prevent signature being executed in other chains and environments
     * @return true --> if valid // false --> if invalid
     */
    function verify(
        bytes32 orderHash,
        address signer,
        bytes calldata sig,
        bytes32 domainSeparator
    ) internal view returns (bool) {
        bytes32 originalDigest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, orderHash)
        );
        bytes32 digest;

        bytes memory extractedSignature;
        if (_isValidBulkOrderSize(sig)) {
            (orderHash, extractedSignature) = _computeBulkOrderProof(
                sig,
                orderHash
            );
            digest = keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, orderHash)
            );
        } else {
            digest = originalDigest;
            extractedSignature = sig;
        }

        _assertValidSignature(
            signer,
            digest,
            originalDigest,
            sig,
            extractedSignature
        );

        return true;
    }

    /**
     * @dev Determines whether the specified bulk order size is valid.
     *
     * @param signature The signature of the bulk order to check.
     *
     * @return validLength True if bulk order size is valid, false otherwise.
     */
    function _isValidBulkOrderSize(
        bytes memory signature
    ) internal pure returns (bool validLength) {
        validLength =
            signature.length < 837 &&
            signature.length > 98 &&
            ((signature.length - 67) % 32) < 2;
    }

    /**
     * @dev Computes the bulk order hash for the specified proof and leaf. Note
     *      that if an index that exceeds the number of orders in the bulk order
     *      payload will instead "wrap around" and refer to an earlier index.
     *
     * @param proofAndSignature The proof and signature of the bulk order.
     * @param leaf              The leaf of the bulk order tree.
     *
     * @return bulkOrderHash The bulk order hash.
     * @return signature     The signature of the bulk order.
     */
    function _computeBulkOrderProof(
        bytes memory proofAndSignature,
        bytes32 leaf
    ) internal pure returns (bytes32 bulkOrderHash, bytes memory signature) {
        bytes32 root = leaf;

        // proofAndSignature with odd length is a compact signature (64 bytes).
        uint256 length = proofAndSignature.length % 2 == 0 ? 65 : 64;

        // Create a new array of bytes equal to the length of the signature.
        signature = new bytes(length);

        // Iterate over each byte in the signature.
        for (uint256 i = 0; i < length; ++i) {
            // Assign the byte from the proofAndSignature to the signature.
            signature[i] = proofAndSignature[i];
        }

        // Compute the key by extracting the next three bytes from the
        // proofAndSignature.
        uint256 key = (((uint256(uint8(proofAndSignature[length])) << 16) |
            ((uint256(uint8(proofAndSignature[length + 1]))) << 8)) |
            (uint256(uint8(proofAndSignature[length + 2]))));

        uint256 height = (proofAndSignature.length - length) / 32;

        // Create an array of bytes32 to hold the proof elements.
        bytes32[] memory proofElements = new bytes32[](height);

        // Iterate over each proof element.
        for (uint256 elementIndex = 0; elementIndex < height; ++elementIndex) {
            // Compute the starting index for the current proof element.
            uint256 start = (length + 3) + (elementIndex * 32);

            // Create a new array of bytes to hold the current proof element.
            bytes memory buffer = new bytes(32);

            // Iterate over each byte in the proof element.
            for (uint256 i = 0; i < 32; ++i) {
                // Assign the byte from the proofAndSignature to the buffer.
                buffer[i] = proofAndSignature[start + i];
            }

            // Decode the current proof element from the buffer and assign it to
            // the proofElements array.
            proofElements[elementIndex] = abi.decode(buffer, (bytes32));
        }

        // Iterate over each proof element.
        for (uint256 i = 0; i < proofElements.length; ++i) {
            // Retrieve the proof element.
            bytes32 proofElement = proofElements[i];

            // Check if the current bit of the key is set.
            if ((key >> i) % 2 == 0) {
                // If the current bit is not set, then concatenate the root and
                // the proof element, and compute the keccak256 hash of the
                // concatenation to assign it to the root.
                root = keccak256(abi.encodePacked(root, proofElement));
            } else {
                // If the current bit is set, then concatenate the proof element
                // and the root, and compute the keccak256 hash of the
                // concatenation to assign it to the root.
                root = keccak256(abi.encodePacked(proofElement, root));
            }
        }

        // Compute the bulk order hash and return it.
        bulkOrderHash = keccak256(
            abi.encodePacked(_lookupBulkOrderTypehash(height), root)
        );

        // Return the signature.
        return (bulkOrderHash, signature);
    }

    /**
     * @dev Internal pure function to look up one of twenty-four potential bulk
     *      order typehash constants based on the height of the bulk order tree.
     *      Note that values between one and twenty-four are supported, which is
     *      enforced by _isValidBulkOrderSize.
     *
     * @param _treeHeight The height of the bulk order tree. The value must be
     *                    between one and twenty-four.
     *
     * @return _typeHash The EIP-712 typehash for the bulk order type with the
     *                   given height.
     */
    function _lookupBulkOrderTypehash(
        uint256 _treeHeight
    ) internal pure returns (bytes32 _typeHash) {
        // Utilize assembly to efficiently retrieve correct bulk order typehash.
        assembly {
            // Use a Yul function to enable use of the `leave` keyword
            // to stop searching once the appropriate type hash is found.
            function lookupTypeHash(treeHeight) -> typeHash {
                // Handle tree heights one through eight.
                if lt(treeHeight, 9) {
                    // Handle tree heights one through four.
                    if lt(treeHeight, 5) {
                        // Handle tree heights one and two.
                        if lt(treeHeight, 3) {
                            // Utilize branchless logic to determine typehash.
                            typeHash := ternary(
                                eq(treeHeight, 1),
                                BulkOrder_Typehash_Height_One,
                                BulkOrder_Typehash_Height_Two
                            )

                            // Exit the function once typehash has been located.
                            leave
                        }

                        // Handle height three and four via branchless logic.
                        typeHash := ternary(
                            eq(treeHeight, 3),
                            BulkOrder_Typehash_Height_Three,
                            BulkOrder_Typehash_Height_Four
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle tree height five and six.
                    if lt(treeHeight, 7) {
                        // Utilize branchless logic to determine typehash.
                        typeHash := ternary(
                            eq(treeHeight, 5),
                            BulkOrder_Typehash_Height_Five,
                            BulkOrder_Typehash_Height_Six
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle height seven and eight via branchless logic.
                    typeHash := ternary(
                        eq(treeHeight, 7),
                        BulkOrder_Typehash_Height_Seven,
                        BulkOrder_Typehash_Height_Eight
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle tree height nine through sixteen.
                if lt(treeHeight, 17) {
                    // Handle tree height nine through twelve.
                    if lt(treeHeight, 13) {
                        // Handle tree height nine and ten.
                        if lt(treeHeight, 11) {
                            // Utilize branchless logic to determine typehash.
                            typeHash := ternary(
                                eq(treeHeight, 9),
                                BulkOrder_Typehash_Height_Nine,
                                BulkOrder_Typehash_Height_Ten
                            )

                            // Exit the function once typehash has been located.
                            leave
                        }

                        // Handle height eleven and twelve via branchless logic.
                        typeHash := ternary(
                            eq(treeHeight, 11),
                            BulkOrder_Typehash_Height_Eleven,
                            BulkOrder_Typehash_Height_Twelve
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle tree height thirteen and fourteen.
                    if lt(treeHeight, 15) {
                        // Utilize branchless logic to determine typehash.
                        typeHash := ternary(
                            eq(treeHeight, 13),
                            BulkOrder_Typehash_Height_Thirteen,
                            BulkOrder_Typehash_Height_Fourteen
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }
                    // Handle height fifteen and sixteen via branchless logic.
                    typeHash := ternary(
                        eq(treeHeight, 15),
                        BulkOrder_Typehash_Height_Fifteen,
                        BulkOrder_Typehash_Height_Sixteen
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle tree height seventeen through twenty.
                if lt(treeHeight, 21) {
                    // Handle tree height seventeen and eighteen.
                    if lt(treeHeight, 19) {
                        // Utilize branchless logic to determine typehash.
                        typeHash := ternary(
                            eq(treeHeight, 17),
                            BulkOrder_Typehash_Height_Seventeen,
                            BulkOrder_Typehash_Height_Eighteen
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle height nineteen and twenty via branchless logic.
                    typeHash := ternary(
                        eq(treeHeight, 19),
                        BulkOrder_Typehash_Height_Nineteen,
                        BulkOrder_Typehash_Height_Twenty
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle tree height twenty-one and twenty-two.
                if lt(treeHeight, 23) {
                    // Utilize branchless logic to determine typehash.
                    typeHash := ternary(
                        eq(treeHeight, 21),
                        BulkOrder_Typehash_Height_TwentyOne,
                        BulkOrder_Typehash_Height_TwentyTwo
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle height twenty-three & twenty-four w/ branchless logic.
                typeHash := ternary(
                    eq(treeHeight, 23),
                    BulkOrder_Typehash_Height_TwentyThree,
                    BulkOrder_Typehash_Height_TwentyFour
                )

                // Exit the function once typehash has been located.
                leave
            }

            // Implement ternary conditional using branchless logic.
            function ternary(cond, ifTrue, ifFalse) -> c {
                c := xor(ifFalse, mul(cond, xor(ifFalse, ifTrue)))
            }

            // Look up the typehash using the supplied tree height.
            _typeHash := lookupTypeHash(_treeHeight)
        }
    }

    /**
     * @dev Internal view function to verify the signature of an order. An
     *      ERC-1271 fallback will be attempted if either the signature length
     *      is not 64 or 65 bytes or if the recovered signer does not match the
     *      supplied signer. Note that in cases where a 64 or 65 byte signature
     *      is supplied, only standard ECDSA signatures that recover to a
     *      non-zero address are supported.
     *
     * @param signer            The signer for the order.
     * @param digest            The digest to verify signature against.
     * @param originalDigest    The original digest to verify signature against.
     * @param originalSignature The original signature.
     * @param signature         A signature from the signer indicating that the
     *                          order has been approved.
     */
    function _assertValidSignature(
        address signer,
        bytes32 digest,
        bytes32 originalDigest,
        bytes memory originalSignature,
        bytes memory signature
    ) internal view {
        if (signer.code.length > 0) {
            // If signer is a contract, try verification via EIP-1271.
            if (
                IERC1271(signer).isValidSignature(
                    originalDigest,
                    originalSignature
                ) != 0x1626ba7e
            ) {
                revert BadContractSignature();
            }

            // Return early if the ERC-1271 signature check succeeded.
            return;
        } else {
            _assertValidSignatureHelper(signer, digest, signature);
        }
    }

    function _assertValidSignatureHelper(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal pure {
        // Declare r, s, and v signature parameters.
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length == 64) {
            // If signature contains 64 bytes, parse as EIP-2098 sig. (r+s&v)
            // Declare temporary vs that will be decomposed into s and v.
            bytes32 vs;

            // Decode signature into r, vs.
            (r, vs) = abi.decode(signature, (bytes32, bytes32));

            // Decompose vs into s and v.
            s = vs & EIP2098_allButHighestBitMask;

            // If the highest bit is set, v = 28, otherwise v = 27.
            v = uint8(uint256(vs >> 255)) + 27;
        } else if (signature.length == 65) {
            (r, s) = abi.decode(signature, (bytes32, bytes32));
            v = uint8(signature[64]);

            // Ensure v value is properly formatted.
            if (v != 27 && v != 28) {
                revert BadSignatureV(v);
            }
        } else {
            revert InvalidSignature();
        }

        // Attempt to recover signer using the digest and signature parameters.
        address recoveredSigner = ecrecover(digest, v, r, s);

        // Disallow invalid signers.
        if (recoveredSigner == address(0) || recoveredSigner != signer) {
            revert InvalidSigner();
        }
    }
}