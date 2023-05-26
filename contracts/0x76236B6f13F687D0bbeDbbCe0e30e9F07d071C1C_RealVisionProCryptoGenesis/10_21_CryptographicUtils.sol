// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/**
 * @dev Contract module used to implement useful cryptography-related functionality.
 */
abstract contract CryptographicUtils is EIP712 {

    constructor(string memory domain, string memory version)
    EIP712(domain, version) {}

    // This version of this overloaded function is used to safeguard operations where the creation of a valid
    // signature (in addition to a tokenId, also) included a specific address
    function _recoverSigner(address relevantAddress, uint256 tokenId, bytes calldata signature) internal view returns (address) {
        // to best understand what is happening in the next line, it is most useful to read the
        // 712 EIP.
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "RVNFTStructWithAddress(uint256 tokenId,address relevantAddress)"),
                        tokenId,
                        relevantAddress)));
        // with the signature provided, and the digest created above it is possible to 'recover'
        // the public address of the account that created the signature.
        return ECDSA.recover(digest, signature);
    }

    // This version of this overloaded function is used to safeguard operations where the creation of a valid
    // signature (in addition to a tokenId, also) included a specific string
    function _recoverSigner(string calldata relevantString, uint256 tokenId, bytes calldata signature) internal view returns (address) {
        // to best understand what is happening in the next line, it is most useful to read the
        // 712 EIP.
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "RVNFTStructWithString(uint256 tokenId,string relevantString)"),
                        tokenId,
                        keccak256(bytes(relevantString)))));
        // with the signature provided, and the digest created above it is possible to 'recover'
        // the public address of the account that created the signature.
        return ECDSA.recover(digest, signature);
    }
}