/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;


/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: contracts/Okashi.sol


/***
 *  
 *  8""""8                      
 *  8      eeeee ee   e eeee    
 *  8eeeee 8   8 88   8 8       
 *      88 8eee8 88  e8 8eee    
 *  e   88 88  8  8  8  88      
 *  8eee88 88  8  8ee8  88ee    
 *  ""8""                       
 *    8   e   e eeee            
 *    8e  8   8 8               
 *    88  8eee8 8eee            
 *    88  88  8 88              
 *    88  88  8 88ee            
 *  8""""8                      
 *  8    8 eeeee eeeee eeee     
 *  8e   8 8   8   8   8        
 *  88   8 8eee8   8e  8eee     
 *  88   8 88  8   88  88       
 *  88eee8 88  8   88  88ee     
 *  
 */

pragma solidity ^0.8.9;









/**
 * @title Save The Date
 * 
 * @notice Everyone has at least one day they hold dear. It may be a birthday, an anniversary, a moment, a memory.
 *         SAVE THE DATE is an NFT project that lets you hold your DATE and continue to celebrate it forever.
 *         Feel.
 *         By creating 1/1 NFT DATEs, each representing 1 day over the last 50 years, we only need to ask which DATE means the world to you?
 *         Celebrate.
 *         After you secure your DATE, in the first year, your DATE will unlock 4 FREE art pieces made by well known artists and all integrate your DATE.
 *         For our first drop, we are excited to announce a partnership with Amber Vittoria.
 *         In addition to the art, DATE holders receive a Celebration Package worth hundreds of dollars of exclusive promotions and benefits from partner 
 *         hotels, restaurants, and brands that would help you celebrate your cherished DATEs.
 * -------------------------------------------------
 * @custom:website https://whatisyourdate.xyz
 * @author Dariusz Tyszka (ArchXS)
 * @custom:security-contact [email protected]
 */
contract SaveTheDate is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    /**
     * @dev Structure representing date to mint as NFT.
     */
    struct DateToMint {
        // Year in format: YYYY
        uint256 year;
        // Month in format: MM
        uint256 month;
        // Day in format: dd
        uint256 day;
        // Wheter the date is randomly selected
        bool isRandom;
        // Additional data veryfing the mint call
        bytes pass;
    }

    /**
     * @dev Structure used to track miniting occurances.
     */
    struct DateToken {
        uint256 tokenId;
        MintType mintType;
        bool isReserved;
        address booker;
        uint256 series;
    }

    /**
     * @dev Structure used to track drop tiers.
     */
    struct DropTier {
        uint256 pieces;
        bool isRevealed;
        uint256 counter;
        uint256 regularPrice;
        uint256 discountedPrice;
    }

    /**
     * @dev Structure used to track drop tiers.
     */
    struct CommunityClaim {
        address tokenContract;
        uint256[] eligibleTokens;
        bool isExempt;
        uint256 maxMints;
    }

    /**
     * @dev Enum used to distinguish minting types.
     */
    enum MintType {
        Bestowal,
        Presale,
        Public
    }

    /**
     * @dev Enum used to distinguish sale phases.
     */
    enum SalesPhase {
        Locked,
        Presale,
        Public
    }

    event DateMinted(string message, string date, MintType mintType, uint256 tokenId, uint256 series, uint256 seriesCount);
    event DateReleased(string message, string date);
    event DropTierChanged(string message, uint256 series);

    uint256 private constant DEFAULT_TOKEN_SUPPLY = 18250;
    uint256 private constant DEFAULT_WALLET_LIMIT = 4;
    uint256 private constant DEFAULT_INCLUSIVE_YEAR = 1972;
    uint256 private constant DEFAULT_EXCLUSIVE_YEAR = 2021;
    uint256 private constant DEFAULT_RELEASE_HOURS = 24;
    uint256 private constant DEFAULT_GIFTS_SUPPLY = 500;

    bytes32 public merkleRoot;
    mapping(address => uint256) public datesClaimed;
    mapping(string => DateToken) public mintedDates;
    mapping(uint256 => string) private _tokenDateURIs;

    string public uriSuffix = ".json";
    
    uint256 public dropSeries;
    uint256 public baselineYear;
    uint256 public rearmostYear;

    bool public suspendedSale = false;
    bool public frozenMetadata = false;
    
    SalesPhase public salesPhase = SalesPhase.Locked;
    uint256 public tokenSupply;
    uint256 public mintsPerWallet;
    uint256 public donatedSupply;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _donatedCounter;
    
    uint256 private _reservedCounter = 0;

    string private _baseTokenUri; 
    string private _contractUri;
    uint256 private _presaleStartTimestamp;
    uint256 private _releaseDatesHours;

    address payable private _donorWallet;
    
    mapping(address => string) private _occupiedDates;
    mapping(uint256 => DropTier) private _dropTiers;
    uint256 private _dropSeriesCount = 0;

    CommunityClaim[] private _communities;
    // collection contract => token Id => claimer wallet
    mapping(address => mapping(uint256 => address)) private _exepmtClaims;
    // claimer wallet => claims count
    mapping(address => uint256) private _communityClaims;

    string private _hiddenTokenUri;

    /**
     * @dev Initializes contract with: 
     *
     * @param hiddenTokenUri Token URI assigned to all tokens before reveal event.
     * @param contractUri Token contract URI for collection of dates.
     */
    constructor(string memory hiddenTokenUri, string memory contractUri, address donorWallet) ERC721("SaveTheDate", "STDT") {
        _hiddenTokenUri = hiddenTokenUri;
        _contractUri = contractUri;
        _releaseDatesHours = DEFAULT_RELEASE_HOURS;

        baselineYear = DEFAULT_INCLUSIVE_YEAR;
        rearmostYear = DEFAULT_EXCLUSIVE_YEAR;

        tokenSupply = DEFAULT_TOKEN_SUPPLY;
        mintsPerWallet = DEFAULT_WALLET_LIMIT;
        donatedSupply = DEFAULT_GIFTS_SUPPLY;

        _donorWallet = payable(donorWallet);
        
        dropSeries = 1;
        _dropTiers[dropSeries].pieces = 1000;
        _dropTiers[dropSeries].regularPrice = 0.1 ether;
        _dropTiers[dropSeries].discountedPrice = 0.05 ether;
        _dropTiers[dropSeries + 1].pieces = 4000;
        _dropTiers[dropSeries + 1].regularPrice = 0.12 ether;
        _dropTiers[dropSeries + 1].discountedPrice = 0.06 ether;
        _dropTiers[dropSeries + 2].pieces = 5000;
        _dropTiers[dropSeries + 2].regularPrice = 0.14 ether;
        _dropTiers[dropSeries + 2].discountedPrice = 0.07 ether;
        _dropTiers[dropSeries + 3].pieces = 8250;
        _dropTiers[dropSeries + 3].regularPrice = 0.16 ether;
        _dropTiers[dropSeries + 3].discountedPrice = 0.08 ether;
        _dropSeriesCount = 4;
    }

    /**
     * @dev Setting up the current drop series. 
     * @param series The subsequent drop series, should be > 1.
     */
    function setDropSeries(uint256 series) public onlyOwner {
        require(series > dropSeries && series <= _dropSeriesCount, "Invalid series");

        dropSeries = series;
    }

    /**
     * @dev Managing the size and number of drop tiers. 
     * @param series The specific sale phase. Only subsequent could be provided and >= 1.
     * @param tier The specific tier parameters.
     */
    function adjustDropTiers(uint256 series, DropTier calldata tier) external onlyOwner {
        require((series >= dropSeries) && (series <= (_dropSeriesCount + 1)) && (tier.pieces <= tokenSupply - tokenCount()), "Invalid tier data");

        _dropTiers[series] = tier;
        if (series == (_dropSeriesCount + 1)) {
            _dropSeriesCount += 1;
        }
        uint256 _tokenSupply = 0;
        for (uint256 i = 1; i <= _dropSeriesCount; i++) {
            _tokenSupply += _dropTiers[i].pieces;
        }

        tokenSupply = _tokenSupply;
	}

    /**
     * @dev Managing sale phases. 
     * @param phase The specific sale phase. Only subsequent Could be provided.
     */
    function beginPhase(SalesPhase phase) external onlyOwner {
		require(uint8(phase) > uint8(salesPhase), "Only next phase possible");

		salesPhase = phase;
        // Pre-sale timestamp
        if (phase == SalesPhase.Presale) {
            _presaleStartTimestamp = block.timestamp;
        }
	}

    /**
     * @dev Managing the period duration after all reserved dates would be freed. 
     * @param hoursToRelease The number of hours to release reservations.
     */
    function adjustReleaseDatesHours(uint hoursToRelease) external onlyOwner {
		_releaseDatesHours = hoursToRelease;
	}

    /**
     * @dev Managing the year of the closing, inclusive dates. 
     * @param year The number representing closing dates range.
     */
    function setRearmostYear(uint256 year) external onlyOwner {
        rearmostYear = year;
    }

    /**
     * @dev Managing the year of the initial, inclusive dates. 
     * @param year The number representing initial dates range.
     */
    function setBaselineYear(uint256 year) external onlyOwner {
        baselineYear = year;
    }

    /**
     * @dev Allows the metadata to be prevented from being changed.
     * @notice Irreversibly!
     */
    function freezeMetadata() external onlyOwner {
		require(!frozenMetadata, "Already frozen");
		frozenMetadata = true;
	}

    /**
     * @dev Allows the number of available tokens to be updated.
     * @param maxSupply The max number of available tokens to set.
     */
    function setTokenSupply(uint256 maxSupply) public onlyOwner {
        require((maxSupply >= donatedSupply) && (maxSupply > tokenCount()), "Invalid max supply");

        tokenSupply = maxSupply;
        uint256 _pieces = 0;
        for (uint256 i = 1; i < _dropSeriesCount; i++) {
            _pieces += _dropTiers[i].pieces;
        }

        _dropTiers[_dropSeriesCount].pieces = maxSupply - _pieces;
    }

    /**
     * @dev Allows the number of available tokens for donations to be updated.
     * @param giftsSupply The max number of available tokens to donate.
     */
    function setDonatedSupply(uint256 giftsSupply) external onlyOwner {
        require((giftsSupply <= tokenSupply) && (giftsSupply > donatedCount()), "Invalid donated supply");

        donatedSupply = giftsSupply;
    }

    /**
     * @notice Only specific number of tokens per walled allowed.
     * @param maxMints Max number of tokens per wallet.
     */
    function setMintsPerWallet(uint256 maxMints) external onlyOwner {
        mintsPerWallet = maxMints;
    }

    /**
     * @dev The address of donor wallet.
     */
    function setDonorWallet(address wallet) external onlyOwner {
        _donorWallet = payable(wallet);
    }

    /**
     * @notice Is used to set the base URI used after reveal.
     * @param tokenUri Base URI for all tokens after reveal.
     */
    function setBaseUri(string memory tokenUri) public onlyOwner {
        require(!frozenMetadata, "Has been frozen"); 
        _baseTokenUri = tokenUri;
    }

    /**
     * @notice Opensea related metadata of the smart contract.
     * @param contractUri Storefront-level metadata for contract.
     */
    function setContractUri(string memory contractUri) external onlyOwner {
        _contractUri = contractUri;
    }

    function setHiddenTokenUri(string memory tokenUri) external onlyOwner {
         require(!frozenMetadata, "Has been frozen"); 
        _hiddenTokenUri = tokenUri;
    }

    function setUriSuffix(string memory suffix) public onlyOwner {
        require(!frozenMetadata, "Has been frozen");
        uriSuffix = suffix;
    }

    function setMerkleRoot(bytes32 newRoot) public onlyOwner {
        merkleRoot = newRoot;
    }

    /**
     * @notice Allows an emergency stop of sale at any time.
     * @param suspended - true if sale is supposed to be suspended.
     */
    function setSuspendedSale(bool suspended) external onlyOwner {
        suspendedSale = suspended;
    }

    /**
     * @notice Allows for defining an eligible communities for claiming dates.
     * @dev Every call overrides the previous settings.
     * @param claimers - The communities definitions.
     */
    function setEligibleCommunities(CommunityClaim[] calldata claimers) external onlyOwner {
        delete _communities;

        for (uint256 i = 0; i < claimers.length; i++) {
            _communities.push(CommunityClaim(claimers[i].tokenContract, claimers[i].eligibleTokens, claimers[i].isExempt, claimers[i].maxMints));
        }   
    }

    function tokenCount() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function donatedCount() public view returns (uint256) {
        return _donatedCounter.current();
    }

    function availableTokenCount() public view returns (uint256) {
        return tokenSupply - (donatedSupply - donatedCount()) - tokenCount();
    }

    function nextToken() internal virtual returns (uint256) {
        _tokenIdCounter.increment();
        uint256 token = _tokenIdCounter.current();
        return token;
    }

    /**
     * @notice Opensea related metadata of the smart contract.
     * @return Storefront-level metadata for contract.
     */
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override (ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenDateURIs[tokenId];
        DateToken memory dateToken = mintedDates[_tokenURI];

        if (!isDropRevealed(dateToken.series)) {
            return _hiddenTokenUri;
        }

        string memory base = _baseURI();
        string memory _tokenDateURI = _tokenURI;

        if (bytes(base).length > 0) {
           _tokenDateURI =  string(abi.encodePacked(base, _tokenURI));
        }

        if (bytes(uriSuffix).length > 0) {
            return string(abi.encodePacked(_tokenDateURI, uriSuffix));
        }

        return _tokenURI;
    }

    /**
     * @notice Allows to set reveal event for each tier.
     * @param series - The given drop series to reveal or not.
     * @param state - true if seriesis supposed to be revealed.
     */
    function setDropsRevealed(uint256[] calldata series, bool state) external onlyOwner {
        require(series.length <= _dropSeriesCount, "Invalid drop series");

        for (uint i = 0; i < series.length; i++) {
            _dropTiers[series[i]].isRevealed = state;
        }
    }

    /**
     * @notice Allows to check the price of the random date within the given drop.
     * @param series - the drop series to check.
     * @return price - the current token price of random dates.
     */
    function checkDatePrice(uint256 series, bool isRandom) external view returns (uint256) {
        return (isRandom ? _dropTiers[series].discountedPrice : _dropTiers[series].regularPrice);
    }

    /**
     * @notice Allows to check wether the given drop is already revealed.
     * @param series - the drop series to check.
     * @return true - if the drop is revealed, false otherwise.
     */
    function isDropRevealed(uint256 series) public view returns (bool) {
        return _dropTiers[series].isRevealed;
    }

    /**
     * @notice Returns the token id for a given date if minted.
     * @param date The object representing date by respectively year, month and day.
     * @return Token ID if the date is already minted, 0 otherwise.
     */
    function tokenByDate(DateToMint calldata date) external view returns (uint256) {
        string memory _tokenDate = _dateToString(date);
        return mintedDates[_tokenDate].tokenId;
    }

    /**
     * @notice Returns the string representing date for a given token ID.
     * @param tokenId The token ID.
     * @return The date minted with this token.
     */
    function dateByToken(uint256 tokenId) external view returns (string memory) {
        return _tokenDateURIs[tokenId];
    }

    /**
     * @notice Allows checking if a given date has not been yet minted or reserved.
     * @param date The object representing date by respectively year, month and day.
     * @return true if date is available to mint or reserve.
     */
    function checkDateAvailability(DateToMint calldata date) public view returns (bool) {
        string memory _tokenDate = _dateToString(date);
        return (!(mintedDates[_tokenDate].tokenId > 0 || (mintedDates[_tokenDate].booker != address(0) && mintedDates[_tokenDate].isReserved)));
    }

    /**
     * @notice Date reservations are held until the specified time period, 
     * after which they are cancelled.
     * @return true if reservations are still kept valid.
     */
    function checkReservationUpheld() public view returns (bool) {
        return (salesPhase == SalesPhase.Presale && block.timestamp <= (_presaleStartTimestamp + (_releaseDatesHours * 3600)));
    }

    /**
     * @notice Check if the caller is on the whitelist
     */
    function verifyWhitelist(bytes32[] calldata merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    /**
     * @notice Allows to check if the given wallet is eligible for community minting.
     * @param collection The colection contract address to check.
     * @param tokenId The token ID of the collection to check, if can be 0 if should be skipped
     * @dev 1. true if the collection is eligible for pre-sale, 
     *      2. true if the given token is eligible for free minting, false otherwise.
     */
    function checkForEligibility(address collection, uint256 tokenId) public view returns (bool eligible, bool exempt) {
        require(Address.isContract(collection), "Invalid contract"); 
        
        for (uint i = 0; i < _communities.length; i++) {
            if (_communities[i].tokenContract == collection) {
                if (_communities[i].isExempt) {
                    uint256[] memory _eligibleTokens = _communities[i].eligibleTokens;

                    for (uint j = 0; j < _eligibleTokens.length; j++) {
                        if (_eligibleTokens[j] == tokenId) {
                            exempt = true;
                            break;
                        }
                    }
                } else {
                    eligible = true;
                }
                if (exempt || eligible) {
                    break;
                }
            }
        }
    }

    /**
     * @notice Check validity of the given date
     * @param date The object representing date by respectively year, month and day.
     * @return true if date is valid to mint.
     */
    function validateDate(DateToMint calldata date) public view returns (bool) {
        return _verifyDate(date.year, date.month, date.day);
    }

    /**
     * @dev A little less complicated brake if for ;)
     */
    function validateCommunityClaim(address claimer) external view returns (bool eligible, bool exempt) {
        (eligible, exempt,,) = _verifyCommunityClaim(claimer);
    }

    /**
     * @notice Date minting function
     * @param tokenDate The object representing the date by respectively year, month and day.
     * @param merkleProof Proof data for vverification against whitelist, empty for public sale.
     * @return Token ID.
     */
    function mintDate(DateToMint calldata tokenDate, bytes32[] calldata merkleProof) external payable ensureAvailability nonReentrant returns (uint256) {

        require(suspendedSale == false, "The sale is suspended");
       // require(salesPhase == SalesPhase.Presale || salesPhase == SalesPhase.Public, "Sale is not active");
        
        bool _eligibleCommunity = false;
        bool _communityExempt = false;
        uint256 _communityIndex = 0;
        uint256 _redeemIndex = 0;

        uint256 tokenPrice = (_communityExempt ? 0 : _dropTiers[dropSeries].regularPrice);

        if (tokenDate.isRandom && !_communityExempt && _validateDiscount(tokenDate)) {
            tokenPrice = _dropTiers[dropSeries].discountedPrice;
        } 

        require(msg.value >= tokenPrice, "Not enough ETH sent; check price!");
        require(datesClaimed[_msgSender()] + 1 <= mintsPerWallet, "Dates already claimed");

        if (salesPhase == SalesPhase.Presale && !_eligibleCommunity && !_communityExempt) {
            require(merkleRoot.length > 0, "Presale forbidden");
            require(verifyWhitelist(merkleProof), "Not allowed at presale");
        } 

        require(_verifyDate(tokenDate.year, tokenDate.month, tokenDate.day), "Invalid date");

        string memory _tokenDate = _dateToString(tokenDate);
        require(mintedDates[_tokenDate].tokenId == 0, "Date already minted");

        // Donated date can't be minted
        require(!mintedDates[_tokenDate].isReserved || (mintedDates[_tokenDate].isReserved && mintedDates[_tokenDate].booker != _donorWallet), "Donated token claim");

        if (salesPhase == SalesPhase.Presale && checkReservationUpheld()) {
            require(!mintedDates[_tokenDate].isReserved || (mintedDates[_tokenDate].isReserved && (mintedDates[_tokenDate].booker == address(0) || mintedDates[_tokenDate].booker == _msgSender())), "Token reservation upheld");
        }

        uint256 tokenId = nextToken();
        _safeMint(_msgSender(), tokenId);
        _setTokenDateURI(tokenId, _tokenDate);
        _setTokenDate(_tokenDate, tokenId);

        if (salesPhase == SalesPhase.Presale) {
            mintedDates[_tokenDate].mintType = MintType.Presale;
        } else {
            mintedDates[_tokenDate].mintType = MintType.Public;        
        }

        datesClaimed[_msgSender()]++;

        if (_eligibleCommunity || _communityExempt) {
            _communityClaims[_msgSender()]++;     
        }
        if (_communityExempt) {
            _redeemExemptToken(_communityIndex, _redeemIndex);
        }

        mintedDates[_tokenDate].series = dropSeries;
        _dropTiers[dropSeries].counter++;

        emit DateMinted("Date minted", _tokenDate, mintedDates[_tokenDate].mintType, tokenId, dropSeries, _dropTiers[dropSeries].counter);

        if (_dropTiers[dropSeries].counter == _dropTiers[dropSeries].pieces) {
            setDropSeries(dropSeries + 1); // Switch to next tier
            emit DropTierChanged("Tier switched up", dropSeries);
        }

        return tokenId;
    }

    /**
     * @dev Special minting function
     */
    function mintDonatedDate(DateToMint calldata tokenDate, address recipient) public ensureAvailability onlyOwner {
        require(donatedCount() + 1 <= donatedSupply, "Gifts run out");

        string memory _tokenDate = _dateToString(tokenDate);
        require(mintedDates[_tokenDate].tokenId == 0 , "Date already minted");

        if (mintedDates[_tokenDate].isReserved && mintedDates[_tokenDate].booker != address(0)) {
            require(mintedDates[_tokenDate].booker == recipient || mintedDates[_tokenDate].booker == _donorWallet, "Invalid recipient");
        }

        uint256 tokenId = nextToken();

        _safeMint(recipient, tokenId);
        _setTokenDateURI(tokenId, _tokenDate);
        _setTokenDate(_tokenDate, tokenId);

        _donatedCounter.increment();
        
        mintedDates[_tokenDate].mintType = MintType.Bestowal;
        mintedDates[_tokenDate].series = dropSeries;
        _dropTiers[dropSeries].counter++;

        if (_dropTiers[dropSeries].counter == _dropTiers[dropSeries].pieces) {
            setDropSeries(dropSeries + 1); // Switch to next tier
            emit DropTierChanged("Tier switched up", dropSeries);
        }
    }

    /**
     * @dev Special batch minting function
     */
    function mintDonatedDates(DateToMint[] calldata tokenDates, address[] calldata recipients) external ensureAvailability onlyOwner {
        require(tokenDates.length == recipients.length, "Invalid call data");

        for (uint i = 0; i < recipients.length; i++) {
            mintDonatedDate(tokenDates[i], recipients[i]);
        }
	}

    /**
     * @dev Special batch date reservation function
     */
    function reserveDates(DateToMint[] calldata bookedDates, address[] calldata bookers) external onlyOwner {
        require(bookedDates.length == bookers.length, "Invalid call data");

        for (uint i = 0; i < bookedDates.length; i++) {
            reserveDate(bookedDates[i], bookers[i]);
        }
    }

    /**
     * @dev Special date reservation function
     */
    function reserveDate(DateToMint calldata bookedDate, address booker) public onlyOwner {
        require(checkDateAvailability(bookedDate), "Date is unavailable");
        require(_verifyDate(bookedDate.year, bookedDate.month, bookedDate.day), "Date is invalid");
        
        string memory _tokenDate = _dateToString(bookedDate);
        
        mintedDates[_tokenDate].booker = booker;
        mintedDates[_tokenDate].isReserved = true; 

         _reservedCounter++; 
    }

    /**
     * @dev Special batch release date function
     */
    function releaseDates(DateToMint[] calldata bookedDates, address[] calldata bookers) external onlyOwner {
        require(bookedDates.length == bookers.length, "Invalid call data");
        
        for (uint i = 0; i < bookedDates.length; i++) {
            releaseDate(bookedDates[i], bookers[i]);
        }
    }

    /**
     * @dev Special release date function
     */
    function releaseDate(DateToMint calldata bookedDate, address booker) public onlyOwner {
        string memory _tokenDate = _dateToString(bookedDate);

        if (mintedDates[_tokenDate].tokenId == 0 && (mintedDates[_tokenDate].isReserved && (mintedDates[_tokenDate].booker == address(0) || mintedDates[_tokenDate].booker == booker))) {
            delete mintedDates[_tokenDate];

            _reservedCounter--;

            emit DateReleased("Date has been released", _tokenDate);
        } 
    }

    // *******************
    // Internal functions
    // *******************

    /**
     * @dev Complicated brake if for ;)
     */
    function _verifyCommunityClaim(address claimer) internal view returns (bool eligible, bool exempt, uint256 communityIndex, uint256 redeemIndex) {
        for (uint i = 0; i < _communities.length; i++) {
            IERC721 communityToken = IERC721(_communities[i].tokenContract);

            uint256 balance = 0;
            try communityToken.balanceOf(claimer) returns (uint256 _balance) {
                balance = _balance;
            } catch {}

            if (balance > 0) {
                communityIndex = i;

                if (_communities[i].isExempt) {
                    uint256[] memory _eligibleTokens = _communities[i].eligibleTokens;

                    for (uint j = 0; j < _eligibleTokens.length; j++) {
                        try communityToken.ownerOf(_eligibleTokens[j]) returns (address _owner) {
                            exempt = (_owner == claimer);
                            if (exempt) {
                                redeemIndex = j;
                                break;
                            }
                        } catch {}
                    }
                } else {
                    eligible = (_communityClaims[claimer] < _communities[i].maxMints);
                }

                if (exempt || eligible) {
                    break;
                }
            }
        }
    }

    /**
     * @dev Allows for validating if the token minting data orygins from official STD app.
     */
    function _validateDiscount(DateToMint calldata tokenDate) internal view returns (bool) {
        if (tokenDate.pass.length > 0) {
            string memory _date = _dateToString(tokenDate);
            bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_date)));
            return (owner() == ECDSA.recover(hash, tokenDate.pass));
        } else {
            return false;
        }
    }

    function _setTokenDate(string memory tokenDate, uint256 tokenId) internal virtual {
        mintedDates[tokenDate].tokenId = tokenId;
    }

    function _setTokenDateURI(uint256 tokenId, string memory _tokenDate) internal virtual {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenDateURIs[tokenId] = _tokenDate;
    }

    function _baseURI() internal view virtual override (ERC721) returns (string memory) {
        return _baseTokenUri;
    }

    // *******************
    // Modifiers
    // *******************
    modifier ensureAvailability() {
        require(availableTokenCount() > 0, "Tokens unavailable");
        _;
    }


    // *******************
    // Utilities
    // *******************

    function withdraw() public onlyOwner nonReentrant {
        uint balance = address(this).balance;
        require(balance > 0, "PCS: No ether left to withdraw");
        Address.sendValue(_donorWallet, balance);
    }

    /*
     * @dev Formating the date data to date string.
     */
    function _dateToString(DateToMint calldata date) internal pure returns (string memory tokenDate) {
        string memory monthSuffix = date.month < 10 ? "0" : "";
        string memory daySuffix = date.day < 10 ? "0" : "";
        tokenDate = string(abi.encodePacked(Strings.toString(date.year), monthSuffix, Strings.toString(date.month), daySuffix, Strings.toString(date.day)));
    }
    
    /*
     * @dev Checking the validity of the specific date data.
     */
    function _verifyDate(uint256 year, uint256 month, uint256 day) internal view returns (bool valid) {
        if ((year >= baselineYear && year <= rearmostYear) && month > 0 && month <= 12) {
            uint256 daysInMonth = _daysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function _isLeapYear(uint256 year) internal pure returns (bool) {
        return ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function _daysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) { 
        if (month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    /**
     * @dev Removing from defined community claims token used for minting date.
     */
    function _redeemExemptToken(uint256 _communityIndex, uint256 _tokenIndex) public {
        require(((_communityIndex < _communities.length) && (_tokenIndex < _communities[_communityIndex].eligibleTokens.length)), "index out of bound");

        for (uint256 i = _tokenIndex; i < _communities[_communityIndex].eligibleTokens.length - 1; i++) {
            _communities[_communityIndex].eligibleTokens[i] = _communities[_communityIndex].eligibleTokens[i + 1];
        }
        _communities[_communityIndex].eligibleTokens.pop();
    }


    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}