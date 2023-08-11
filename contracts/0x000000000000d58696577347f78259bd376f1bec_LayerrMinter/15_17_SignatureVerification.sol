// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {EIP712Domain, MintOrder, MintParameters, MintToken, BurnToken, PaymentToken} from "./MinterStructs.sol";
import {EIP712_DOMAIN_TYPEHASH, MINTPARAMETERS_TYPEHASH, MINTTOKEN_TYPEHASH, BURNTOKEN_TYPEHASH, PAYMENTTOKEN_TYPEHASH} from "./TypeHashes.sol";

/**
 * @title SignatureVerification
 * @author 0xth0mas (Layerr)
 * @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/EIP712.sol)
 * @author Modified from Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/utils/EIP712.sol)
 * @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/EIP712.sol)
 * @notice Recovers the EIP712 signer for MintParameters and oracle signers
 *         for the LayerrMinter contract.
 */
contract SignatureVerification {
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    string private constant _name = "LayerrMinter";
    string private constant _version = "1.0";

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    constructor() {
        _hashedName = keccak256(bytes(_name));
        _hashedVersion = keccak256(bytes(_version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }
    
    /**
     * @notice Recovers the signer address for the supplied mint parameters and signature
     * @param input MintParameters to recover the signer for
     * @param signature Signature for the MintParameters `_input` to recover signer
     * @return signer recovered signer of `signature` and `_input`
     * @return digest hash digest of `_input`
     */
    function _recoverMintParametersSigner(
        MintParameters calldata input,
        bytes calldata signature
    ) internal view returns (address signer, bytes32 digest) {
        bytes32 hash = _getMintParametersHash(input);
        digest = keccak256(
            abi.encodePacked("\x19\x01", _domainSeparator(), hash)
        );
        signer = _recover(digest, signature);
    }

    /**
     * @notice Recovers the signer address for the supplied oracle signature
     * @param minter address of wallet performing the mint
     * @param mintParametersSignature signature of MintParameters to check oracle signature of
     * @param oracleSignature supplied oracle signature
     * @return signer recovered oracle signer address
     */
    function _recoverOracleSigner(
        address minter, 
        bytes calldata mintParametersSignature, 
        bytes calldata oracleSignature
    ) internal pure returns(address signer) {
        bytes32 digest = keccak256(abi.encodePacked(minter, mintParametersSignature));
        signer = _recover(digest, oracleSignature);
    }

    /**
     * @notice Recovers the signer address for the increment nonce transaction
     * @param signer address of the account to increment nonce
     * @param currentNonce current nonce for the signer account
     * @param signature signature of message to validate
     * @return valid if the signature came from the signer
     */
    function _validateIncrementNonceSigner(
        address signer, 
        uint256 currentNonce,
        bytes calldata signature
    ) internal view returns(bool valid) {
        unchecked {
            // add chain id to current nonce to guard against replay on other chains
            currentNonce += block.chainid;
        }
        bytes memory nonceString = bytes(_toString(currentNonce));
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", _toString(nonceString.length), nonceString));
        valid = signer == _recover(digest, signature) && signer != address(0);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparator() private view returns (bytes32 separator) {
        separator = _cachedDomainSeparator;
        if (_cachedDomainSeparatorInvalidated()) {
            separator = _buildDomainSeparator();
        }
    }

    /**
     *  @dev Returns if the cached domain separator has been invalidated.
     */ 
    function _cachedDomainSeparatorInvalidated() private view returns (bool result) {
        uint256 cachedChainId = _cachedChainId;
        address cachedThis = _cachedThis;
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(and(eq(chainid(), cachedChainId), eq(address(), cachedThis)))
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    _hashedName,
                    _hashedVersion,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function _recover(
        bytes32 hash,
        bytes calldata sig
    ) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        /// @solidity memory-safe-assembly
        assembly {
            r := calldataload(sig.offset)
            s := calldataload(add(sig.offset, 32))
            v := byte(0, calldataload(add(sig.offset, 64)))
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := add(mload(0x40), 0xa0)
            mstore(0x40, m)
            str := sub(m, 0x20)
            mstore(str, 0)
            let end := str

            for { let temp := value } 1 {} {
                str := sub(str, 1)
                mstore8(str, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            str := sub(str, 0x20)
            mstore(str, length)
        }
    }

    function _getMintTokenArrayHash(
        MintToken[] calldata mintTokens
    ) internal pure returns (bytes32 hash) {
        bytes memory encoded;
        for (uint256 i = 0; i < mintTokens.length; ) {
            encoded = abi.encodePacked(encoded, _getMintTokenHash(mintTokens[i]));
            unchecked {
                ++i;
            }
        }
        hash = keccak256(encoded);
    }

    function _getBurnTokenArrayHash(
        BurnToken[] calldata burnTokens
    ) internal pure returns (bytes32 hash) {
        bytes memory encoded;
        for (uint256 i = 0; i < burnTokens.length; ) {
            encoded = abi.encodePacked(encoded, _getBurnTokenHash(burnTokens[i]));
            unchecked {
                ++i;
            }
        }
        hash = keccak256(encoded);
    }

    function _getPaymentTokenArrayHash(
        PaymentToken[] calldata paymentTokens
    ) internal pure returns (bytes32 hash) {
        bytes memory encoded;
        for (uint256 i = 0; i < paymentTokens.length; ) {
            encoded = abi.encodePacked(encoded, _getPaymentTokenHash(paymentTokens[i]));
            unchecked {
                ++i;
            }
        }
        hash = keccak256(encoded);
    }

    function _getMintTokenHash(
        MintToken calldata mintToken
    ) internal pure returns (bytes32 hash) {
        hash = keccak256(
            abi.encode(
                MINTTOKEN_TYPEHASH,
                mintToken.contractAddress,
                mintToken.specificTokenId,
                mintToken.tokenType,
                mintToken.tokenId,
                mintToken.mintAmount,
                mintToken.maxSupply,
                mintToken.maxMintPerWallet
            )
        );
    }

    function _getBurnTokenHash(
        BurnToken calldata burnToken
    ) internal pure returns (bytes32 hash) {
        hash = keccak256(
            abi.encode(
                BURNTOKEN_TYPEHASH,
                burnToken.contractAddress,
                burnToken.specificTokenId,
                burnToken.tokenType,
                burnToken.burnType,
                burnToken.tokenId,
                burnToken.burnAmount
            )
        );
    }

    function _getPaymentTokenHash(
        PaymentToken calldata paymentToken
    ) internal pure returns (bytes32 hash) {
        hash = keccak256(
            abi.encode(
                PAYMENTTOKEN_TYPEHASH,
                paymentToken.contractAddress,
                paymentToken.tokenType,
                paymentToken.payTo,
                paymentToken.paymentAmount,
                paymentToken.referralBPS
            )
        );
    }

    function _getMintParametersHash(
        MintParameters calldata mintParameters
    ) internal pure returns (bytes32 hash) {
        bytes memory encoded = abi.encode(
            MINTPARAMETERS_TYPEHASH,
            _getMintTokenArrayHash(mintParameters.mintTokens),
            _getBurnTokenArrayHash(mintParameters.burnTokens),
            _getPaymentTokenArrayHash(mintParameters.paymentTokens),
            mintParameters.startTime,
            mintParameters.endTime,
            mintParameters.signatureMaxUses,
            mintParameters.merkleRoot,
            mintParameters.nonce,
            mintParameters.oracleSignatureRequired
        );
        hash = keccak256(encoded);
    }

    function getMintParametersSignatureDigest(
        MintParameters calldata mintParameters
    ) external view returns (bytes32 digest) {
        bytes32 hash = _getMintParametersHash(mintParameters);
        digest = keccak256(
            abi.encodePacked("\x19\x01", _domainSeparator(), hash)
        );
    }
}