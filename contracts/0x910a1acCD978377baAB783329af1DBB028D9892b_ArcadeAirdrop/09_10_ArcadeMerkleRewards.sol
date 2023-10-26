// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/INFTBoostVault.sol";

import {
    AA_ClaimingExpired,
    AA_AlreadyClaimed,
    AA_NonParticipant,
    AA_ZeroAddress,
    AA_NotInitialized
} from "../errors/Airdrop.sol";

/**
 * @title Arcade Merkle Rewards
 * @author Non-Fungible Technologies, Inc.
 *
 * This contract validates merkle proofs and allows users to claim their airdrop. It is designed to
 * be inherited by other contracts. This contract does not have a way to transfer tokens out of it
 * or change the merkle root.
 *
 * As users claim their tokens, this contract will deposit them into a voting vault for use in
 * Arcade Governance. When claiming, the user can delegate voting power to themselves or another
 * account.
 */
abstract contract ArcadeMerkleRewards {
    // ============================================ STATE ==============================================

    // =================== Immutable references =====================

    /// @notice the token to airdrop
    IERC20 public immutable token;

    // ==================== Reward Claim State ======================

    /// @notice the merkle root with deposits encoded into it as hash [address, amount]
    bytes32 public rewardsRoot;

    /// @notice the timestamp expiration of the rewards root
    uint256 public expiration;

    /// @notice user claim history by merkle root used to claim
    mapping(address => mapping(bytes32 => uint256)) public claimed;

    /// @notice the voting vault vault which receives airdropped tokens
    INFTBoostVault public votingVault;

    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @notice Initiate the contract with a merkle tree root, a token for distribution,
     *         an expiration time for claims, and the voting vault that tokens will be
     *         airdropped into.
     *
     * @param _rewardsRoot           The merkle root with deposits encoded into it as hash [address, amount]
     * @param _token                 The token to airdrop
     * @param _expiration            The expiration of the airdrop
     * @param _votingVault           The voting vault to deposit tokens to
     */
    constructor(bytes32 _rewardsRoot, IERC20 _token, uint256 _expiration, INFTBoostVault _votingVault) {
        if (_expiration <= block.timestamp) revert AA_ClaimingExpired();
        if (address(_token) == address(0)) revert AA_ZeroAddress("token");
        if (address(_votingVault) == address(0)) revert AA_ZeroAddress("votingVault");

        rewardsRoot = _rewardsRoot;
        token = _token;
        expiration = _expiration;
        votingVault = _votingVault;
    }

    // ===================================== CLAIM FUNCTIONALITY ========================================

    /**
     * @notice Claims an amount of tokens in the tree and delegates to governance. If the user has
     *         not received an airdrop, they can claim it and delegate to themselves by passing in
     *         their address as the delegate or address(0). If a user has claimed before, they must
     *         use the same delegate address they are already delegating to.
     *
     * @param delegate               The address the user will delegate to
     * @param totalGrant             The total amount of tokens the user was granted
     * @param merkleProof            The merkle proof showing the user is in the merkle tree
     */
    function claimAndDelegate(address delegate, uint128 totalGrant, bytes32[] calldata merkleProof) external {
        if (rewardsRoot == bytes32(0)) revert AA_NotInitialized();
        // must be before the expiration time
        if (block.timestamp > expiration) revert AA_ClaimingExpired();
        // validate the withdraw
        _validateWithdraw(totalGrant, merkleProof);

        // approve the voting vault to transfer tokens
        token.approve(address(votingVault), uint256(totalGrant));
        // deposit tokens in voting vault for this msg.sender and delegate
        votingVault.airdropReceive(msg.sender, totalGrant, delegate);
    }

    // =========================================== HELPERS ==============================================

    /**
     * @notice Validate a withdraw attempt by checking merkle proof and ensuring the user has not
     *         previously withdrawn.
     *
     * @param totalGrant             The total amount of tokens the user was granted
     * @param merkleProof            The merkle proof showing the user is in the merkle tree
     */
    function _validateWithdraw(uint256 totalGrant, bytes32[] memory merkleProof) internal {
        // validate proof and leaf hash
        bytes32 leafHash = keccak256(abi.encodePacked(msg.sender, totalGrant));
        if (!MerkleProof.verify(merkleProof, rewardsRoot, leafHash)) revert AA_NonParticipant();

        // ensure the user has not already claimed the airdrop for this merkle root
        if (claimed[msg.sender][rewardsRoot] != 0) revert AA_AlreadyClaimed();
        claimed[msg.sender][rewardsRoot] = totalGrant;
    }
}