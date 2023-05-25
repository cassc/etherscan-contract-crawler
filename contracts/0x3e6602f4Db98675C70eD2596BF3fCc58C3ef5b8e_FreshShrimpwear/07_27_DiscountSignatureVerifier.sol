// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract DiscountSignatureVerifier {
    struct DiscountRequest {
        address to;
        bytes32 uid;
        bytes32 orderId;
        uint256 totalDiscount;
    }

    // map address to bool to check if address used discount once
    mapping(address => bool) public addressUsedDiscount;

    bytes32 private constant MINT_REQUEST_TYPEHASH =
        keccak256(
            "DiscountRequest(address to,bytes32 uid,bytes32 orderId,uint256 totalDiscount)"
        );
    bytes32 private constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    // make mapping for used signatures by its uid
    mapping(bytes32 => bool) public usedDiscountSignatures;

    string private constant DOMAIN_NAME = "DiscountSignatureVerifier";
    string private constant DOMAIN_VERSION = "1.0.0";
    uint256 private constant CHAIN_ID = 1;

    function getMessageHash(
        DiscountRequest memory discountRequest
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
                discountRequest.to,
                discountRequest.uid,
                discountRequest.orderId,
                discountRequest.totalDiscount
            )
        );
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, requestHash)
            );
    }

    function recoverDiscountSignatureSigner(
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

    function getAddressFromDiscountSignature(
        DiscountRequest memory discountRequest,
        bytes memory signature
    ) public view returns (address) {
        bytes32 messageHash = getMessageHash(discountRequest);
        return recoverDiscountSignatureSigner(messageHash, signature);
    }

    function checkDiscountSignature(bytes32 uid) internal view returns (bool) {
        // Check if the signature has been used before
        if (usedDiscountSignatures[uid]) {
            return false;
        }

        if (addressUsedDiscount[msg.sender]) {
            return false;
        }

        return true;
    }

    function checkAddressUsedDiscount(address addr) public view returns (bool) {
        return addressUsedDiscount[addr];
    }

    function useDiscountSignature(bytes32 uid) internal {
        usedDiscountSignatures[uid] = true;
        addressUsedDiscount[msg.sender] = true;
    }

    constructor() {}
}