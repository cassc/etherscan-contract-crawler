// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

/**
 * @title Fair.xyz Editions Constants
 * @dev This contract contains all of the constants and immutable values used in the Fair.xyz Editions contracts.
 * @dev IMPORTANT: This should not have any variables which use storage slots - as a result it is possible to be inherited by upgradeable contracts without the need for a storage 'gap'.
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable
 */
contract FairxyzEditionsConstants {
    // * SIGNATURES * //
    bytes32 internal constant EIP712_NAME_HASH = keccak256("Fair.xyz");
    bytes32 internal constant EIP712_VERSION_HASH = keccak256("2.0.0");
    bytes32 internal constant EIP712_DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 internal constant EIP712_EDITION_MINT_TYPE_HASH =
        keccak256(
            "EditionMint(uint256 editionId,address recipient,uint256 quantity,uint256 nonce,uint256 maxMints)"
        );

    // * ROLES * //
    bytes32 internal constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    bytes32 internal constant EXTERNAL_MINTER_ROLE =
        keccak256("EXTERNAL_MINTER_ROLE");

    uint256 internal constant ROYALTY_DENOMINATOR = 10000;
    uint256 internal constant SIGNATURE_VALID_BLOCKS = 75;

    // * IMMUTABLES * //
    uint256 internal immutable FAIRXYZ_MINT_FEE;
    address internal immutable FAIRXYZ_RECEIVER_ADDRESS;
    address internal immutable FAIRXYZ_FAIRXYZ_SIGNER_ADDRESS;
    address internal immutable FAIRXYZ_STAGES_REGISTRY;

    uint256 internal immutable MAX_EDITION_SIZE;
    uint256 internal immutable MAX_RECIPIENTS_PER_AIRDROP;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        uint256 fairxyzMintFee_,
        address fairxyzReceiver_,
        address fairxyzSigner_,
        address fairxyzStagesRegistry_,
        uint256 maxEditionSize_,
        uint256 maxRecipientsPerAirdrop_
    ) {
        FAIRXYZ_MINT_FEE = fairxyzMintFee_;
        FAIRXYZ_RECEIVER_ADDRESS = fairxyzReceiver_;
        FAIRXYZ_FAIRXYZ_SIGNER_ADDRESS = fairxyzSigner_;
        FAIRXYZ_STAGES_REGISTRY = fairxyzStagesRegistry_;

        MAX_EDITION_SIZE = maxEditionSize_;
        MAX_RECIPIENTS_PER_AIRDROP = maxRecipientsPerAirdrop_;
    }
}