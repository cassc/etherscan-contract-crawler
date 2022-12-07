// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SignatureInfo {
    bytes32 constant CONTENT_HASH =
        0x58e2f0ec35eb789493367bbd774d478d0e7e6916118069574ff2690b38004245;

    struct Content {
        address holder;
        uint128 amount;
        string identity;
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s;
    }

    function getContentHash(Content calldata content)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    CONTENT_HASH,
                    content.holder,
                    content.amount,
                    keccak256(bytes(content.identity))
                )
            );
    }

    struct InfoSet {
        uint48 dsMintStart;
        uint48 dsDuration;
        uint48 earlyMintStart;
        uint48 earlyMintDuration;
        uint32 publicMintStart;
        uint32 publicMintDuration;
        uint256 price;
    }
}

library SignatureChecker {
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Signature: Invalid s parameter"
        );

        require(v == 27 || v == 28, "Signature: Invalid v parameter");
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "Signature: Invalid signer");

        return signer;
    }

    function verify(
        bytes32 hash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 domainSeparator
    ) internal pure returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, hash)
        );
        return recover(digest, v, r, s) == signer;
    }
}