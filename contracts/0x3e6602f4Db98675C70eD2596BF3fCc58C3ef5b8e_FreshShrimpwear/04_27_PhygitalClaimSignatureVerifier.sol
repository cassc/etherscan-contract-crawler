// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract PhygitalClaimSignatureVerifier {
    struct PhygitalClaimRequest {
        address to;
        string uri;
        bytes32 uid;
        bytes32 userId;
        uint48 claimedAt;
        uint256 tokenId;
    }

    bytes32 private constant MINT_REQUEST_TYPEHASH =
        keccak256(
            "PhygitalClaimRequest(address to,string uri,bytes32 uid,bytes32 userId,uint48 claimedAt,uint256 tokenId)"
        );
    bytes32 private constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    // make mapping for used signatures by its uid
    mapping(bytes32 => bool) public usedPhygitalClaimSignatures;

    string private constant DOMAIN_NAME = "PhygitalClaimSignatureVerifier";
    string private constant DOMAIN_VERSION = "1.0.0";
    uint256 private constant CHAIN_ID = 80001;

    function getMessageHash(
        PhygitalClaimRequest memory mintRequest
    ) private view returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(DOMAIN_NAME)),
                keccak256(bytes(DOMAIN_VERSION)),
                CHAIN_ID,
                address(this)
            )
        );
        bytes32 requestHash = keccak256(
            abi.encode(
                MINT_REQUEST_TYPEHASH,
                mintRequest.to,
                keccak256(bytes(mintRequest.uri)),
                mintRequest.uid,
                mintRequest.userId,
                mintRequest.claimedAt,
                mintRequest.tokenId
            )
        );
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, requestHash)
            );
    }

    function recoverPhygitalClaimSigner(
        bytes32 messageHash,
        bytes memory signature
    ) private pure returns (address) {
        require(signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "invalid signature v value");
        return ecrecover(messageHash, v, r, s);
    }

    function getAddressFromPhygitalClaimSignature(
        PhygitalClaimRequest memory mintRequest,
        bytes memory signature
    ) public view returns (address) {
        bytes32 messageHash = getMessageHash(mintRequest);
        return recoverPhygitalClaimSigner(messageHash, signature);
    }

    function checkPhygitalClaimSignature(bytes32 uid) public view returns (bool) {
        // Check if the signature has been used before
        if (usedPhygitalClaimSignatures[uid]) {
            return false;
        }

        return true;
    }

    function usePhygitalClaimSignature(bytes32 uid) internal {
        usedPhygitalClaimSignatures[uid] = true;
    }

    constructor() {}
}