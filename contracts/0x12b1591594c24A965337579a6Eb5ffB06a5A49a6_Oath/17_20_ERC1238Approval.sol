// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

// Typed data of a Mint Batch transaction
// needing to be approved by `recipient`.
struct MintBatchApproval {
    address recipient;
    uint256[] ids;
    uint256[] amounts;
    uint256 approvalExpiry;
}

// Typed data of a Mint transaction
// needing to be approved by `recipient`.
struct MintApproval {
    address recipient;
    uint256 id;
    uint256 amount;
    uint256 approvalExpiry;
}

struct MintApprovalSignature {
    uint8 v;
    bytes32 r;
    bytes32 s;
    uint256 approvalExpiry;
}

/**
 * ERC1238 tokens can only be minted to an EOA by providing a message signed by the recipient to
 * approve the minting, or batch minting, of tokens.
 *
 * This contract contains the logic around generating and verifiying these signed messages.
 *
 * @dev The implementation is based on EIP-712, a standard for typed structured data hashing and signing.
 * The standard defines the `hashtruct` function where structs are encoded with their typeHash
 * (a constant defining their type) and hashed.
 * See https://eips.ethereum.org/EIPS/eip-712
 *
 */
contract ERC1238Approval {
    bytes32 private constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 private constant MINT_APPROVAL_TYPEHASH =
        keccak256(
            "MintApproval(address recipient,uint256 id,uint256 amount,uint256 approvalExpiry)"
        );

    bytes32 private constant MINT_BATCH_APPROVAL_TYPEHASH =
        keccak256(
            "MintBatchApproval(address recipient,uint256[] ids,uint256[] amounts,uint256 approvalExpiry)"
        );

    // Domain Separator, as defined by EIP-712 (`hashstruct(eip712Domain)`)
    bytes32 public DOMAIN_SEPARATOR;

    mapping(bytes32 => bool) private hasApprovalHashBeenUsed;

    constructor() {
        // The EIP712Domain shares the same name for all ERC128Approval contracts
        // but the unique address of this contract as `verifiyingContract`
        EIP712Domain memory eip712Domain = EIP712Domain({
            name: "ERC1238 Mint Approval",
            version: "1",
            chainId: block.chainid,
            verifyingContract: address(this)
        });

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(eip712Domain.name)),
                keccak256(bytes(eip712Domain.version)),
                eip712Domain.chainId,
                eip712Domain.verifyingContract
            )
        );
    }

    /**
     * @dev Returns a MintApprovalMessageHash which is the result of `hashstruct(MintApproval)`.
     * To verify that `recipient` approved a mint transaction, the hash returned
     * must be passed to _verifyMintingApproval as `mintApprovalHash`.
     *
     */
    function _getMintApprovalMessageHash(
        address recipient,
        uint256 id,
        uint256 amount,
        uint256 approvalExpiry
    ) internal pure returns (bytes32) {
        MintApproval memory mintApproval = MintApproval({
            recipient: recipient,
            id: id,
            amount: amount,
            approvalExpiry: approvalExpiry
        });
        return
            keccak256(
                abi.encode(
                    MINT_APPROVAL_TYPEHASH,
                    mintApproval.recipient,
                    mintApproval.id,
                    mintApproval.amount,
                    mintApproval.approvalExpiry
                )
            );
    }

    /**
     * @dev Returns a MintBatchApprovalMessageHash which is the result of `hashstruct(MintBatchApproval)`.
     * To verify that `recipient` approved a mint batch transaction, the hash returned
     * must be passed to _verifyMintingApproval as `mintApprovalHash`.
     *
     */
    function _getMintBatchApprovalMessageHash(
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256 approvalExpiry
    ) internal pure returns (bytes32) {
        MintBatchApproval memory mintBatchApproval = MintBatchApproval({
            recipient: recipient,
            ids: ids,
            amounts: amounts,
            approvalExpiry: approvalExpiry
        });

        return
            keccak256(
                abi.encode(
                    MINT_BATCH_APPROVAL_TYPEHASH,
                    mintBatchApproval.recipient,
                    keccak256(abi.encodePacked(mintBatchApproval.ids)),
                    keccak256(abi.encodePacked(mintBatchApproval.amounts)),
                    mintBatchApproval.approvalExpiry
                )
            );
    }

    /**
     * @dev Given a mintApprovalHash (either MintApprovalMessageHash or MintBatchApprovalMessageHash),
     * this function verifies if the signature (v, r, and s) was signed by `recipient` based on the
     * EIP712Domain of this contract, and otherwise reverts.
     */
    function _verifyMintingApproval(
        address recipient,
        bytes32 mintApprovalHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        // Prevent signatures from being replayed
        require(!hasApprovalHashBeenUsed[mintApprovalHash], "ERC1238: Approval hash already used");

        bytes32 digest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, mintApprovalHash);

        require(
            ECDSA.recover(digest, v, r, s) == recipient,
            "ERC1238: Approval verification failed"
        );

        hasApprovalHashBeenUsed[mintApprovalHash] = true;
    }
}