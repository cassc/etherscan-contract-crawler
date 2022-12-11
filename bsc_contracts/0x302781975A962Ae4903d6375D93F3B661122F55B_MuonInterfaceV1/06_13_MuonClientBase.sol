// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/SchnorrSECP256K1Verifier.sol";
import "hardhat/console.sol";

contract MuonClientBase is SchnorrSECP256K1Verifier {
    struct SchnorrSign {
        uint256 signature;
        address owner;
        address nonce;
    }

    struct PublicKey {
        uint256 x;
        uint8 parity;
    }

    event MuonTX(bytes reqId, PublicKey pubKey);

    uint256 public muonAppId;
    PublicKey public muonPublicKey;

    function muonVerify(
        bytes calldata reqId,
        uint256 hash,
        SchnorrSign memory signature,
        PublicKey memory pubKey
    ) public returns (bool) {
        if (
            !verifySignature(
                pubKey.x,
                pubKey.parity,
                signature.signature,
                hash,
                signature.nonce
            )
        ) {
            return false;
        }
        emit MuonTX(reqId, pubKey);
        return true;
    }
}