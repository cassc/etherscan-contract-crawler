/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "../ReliquaryWithFee.sol";
import "../RelicToken.sol";
import "../BlockHistory.sol";
import "./StateVerifier.sol";

/**
 * @title BirthCertificateProver
 * @author Theori, Inc.
 * @notice BirthCertificateProver proves that an account existed in a given block
 *         and stores the oldest known account proof in the fact database
 */
contract BirthCertificateProver is StateVerifier {
    FactSignature public immutable BIRTH_CERTIFICATE_SIG;
    RelicToken immutable token;

    constructor(
        BlockHistory blockHistory,
        ReliquaryWithFee _reliquary,
        RelicToken _token
    ) StateVerifier(blockHistory, _reliquary) {
        BIRTH_CERTIFICATE_SIG = Facts.toFactSignature(Facts.NO_FEE, abi.encode("BirthCertificate"));
        token = _token;
    }

    /**
     * @notice Proves that an account existed in the given block. Stores the
     *         fact in the registry if the given block is the oldest block
     *         this account is known to exist in.
     *
     * @param account the account to prove exists
     * @param accountProof the Merkle-Patricia trie proof for the account
     * @param header the block header, RLP encoded
     * @param blockProof proof that the block header is valid
     */
    function proveBirthCertificate(
        address account,
        bytes calldata accountProof,
        bytes calldata header,
        bytes calldata blockProof
    ) external payable {
        reliquary.checkProveFactFee{value: msg.value}(msg.sender);

        (bool exists, CoreTypes.BlockHeaderData memory head, ) = verifyAccountAtBlock(
            account,
            accountProof,
            header,
            blockProof
        );
        require(exists, "Account does not exist at block");

        (bool proven, , bytes memory data) = reliquary.getFact(account, BIRTH_CERTIFICATE_SIG);

        if (proven) {
            uint48 blockNum = uint48(bytes6(data));
            require(blockNum >= head.Number, "older block already proven");
        }

        data = abi.encodePacked(uint48(head.Number), uint64(head.Time));
        reliquary.setFact(account, BIRTH_CERTIFICATE_SIG, data);

        if (!proven) {
            token.mint(account, 0);
        }
    }
}