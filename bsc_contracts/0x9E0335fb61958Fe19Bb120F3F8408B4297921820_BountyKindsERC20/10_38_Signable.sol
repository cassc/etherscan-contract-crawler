// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Context} from "../oz/utils/Context.sol";
import {ECDSA, EIP712} from "../oz/utils/cryptography/draft-EIP712.sol";

import {ISignable} from "./interfaces/ISignable.sol";

import {Bytes32Address} from "../libraries/Bytes32Address.sol";

/**
 * @title Signable
 * @dev Abstract contract for signing and verifying typed data.
 */
abstract contract Signable is Context, EIP712, ISignable {
    using ECDSA for bytes32;
    using Bytes32Address for address;

    /**
     * @dev Mapping of nonces for each id
     */
    mapping(bytes32 => uint256) internal _nonces;

    /**
     * @dev Constructor that initializes EIP712 with the given name and version
     * @param name_ Name of the typed data
     * @param version_ Version of the typed data
     */
    constructor(
        string memory name_,
        string memory version_
    ) payable EIP712(name_, version_) {}

    /**
     * @dev Verifies that the signer of the typed data is the given address
     * @param verifier_ Address to verify
     * @param structHash_ Hash of the typed data
     * @param signature_ Signature of the typed data
     */
    function _verify(
        address verifier_,
        bytes32 structHash_,
        bytes calldata signature_
    ) internal view virtual {
        if (_recoverSigner(structHash_, signature_) != verifier_)
            revert Signable__InvalidSignature();
    }

    /**
     * @dev Verifies that the signer of the typed data is the given address
     * @param verifier_ Address to verify
     * @param structHash_ Hash of the typed data
     * @param v ECDSA recovery value
     * @param r ECDSA r value
     * @param s ECDSA s value
     */
    function _verify(
        address verifier_,
        bytes32 structHash_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view virtual {
        if (_recoverSigner(structHash_, v, r, s) != verifier_)
            revert Signable__InvalidSignature();
    }

    /**
     * @dev Recovers the signer of the typed data from the signature
     * @param structHash_ Hash of the typed data
     * @param signature_ Signature of the typed data
     * @return Address of the signer
     */
    function _recoverSigner(
        bytes32 structHash_,
        bytes calldata signature_
    ) internal view returns (address) {
        return _hashTypedDataV4(structHash_).recover(signature_);
    }

    /**
     * @dev Recovers the signer of the typed data from the signature
     * @param structHash_ Hash of the typed data
     * @param v ECDSA recovery value
     * @param r ECDSA r value
     * @param s ECDSA s value
     * @return Address of the signer
     */
    function _recoverSigner(
        bytes32 structHash_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address) {
        return _hashTypedDataV4(structHash_).recover(v, r, s);
    }

    /**
     * @dev Increases the nonce for the given account by 1
     * @param id_ ID to increase the nonce for
     * @return nonce The new nonce for the account
     */
    function _useNonce(bytes32 id_) internal virtual returns (uint256 nonce) {
        assembly {
            mstore(0x00, id_)
            mstore(0x20, _nonces.slot)
            let key := keccak256(0x00, 0x40)
            nonce := sload(key)
            sstore(key, add(nonce, 1))
        }

        emit NonceIncremented(_msgSender(), id_, nonce);
    }

    /// @inheritdoc ISignable
    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }
}