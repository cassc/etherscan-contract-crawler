// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../external/council/libraries/Authorizable.sol";

import "../libraries/ArcadeMerkleRewards.sol";

import { AA_ClaimingNotExpired, AA_ClaimingExpired, AA_ZeroAddress } from "../errors/Airdrop.sol";

/**
 * @title Arcade Airdrop
 * @author Non-Fungible Technologies, Inc.
 *
 * This contract receives tokens from the ArcadeTokenDistributor and facilitates airdrop claims.
 * The contract is ownable, where the owner can reclaim any remaining tokens once the airdrop is
 * over and also change the merkle root and its expiration at their discretion.
 */
contract ArcadeAirdrop is ArcadeMerkleRewards, Authorizable {
    using SafeERC20 for IERC20;

    // ============================================= EVENTS =============================================

    event SetMerkleRoot(bytes32 indexed merkleRoot, uint256 indexed expiration);

    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @notice Initiate the contract with a merkle tree root, a token for distribution,
     *         an expiration time for claims, and the voting vault that tokens will be
     *         airdropped into.
     *
     * @param _merkleRoot           The merkle root with deposits encoded into it as hash [address, amount]
     * @param _token                The token to airdrop
     * @param _expiration           The expiration of the airdrop
     * @param _votingVault          The voting vault to deposit tokens to
     */
    constructor(
        bytes32 _merkleRoot,
        IERC20 _token,
        uint256 _expiration,
        INFTBoostVault _votingVault
    ) ArcadeMerkleRewards(_merkleRoot, _token, _expiration, _votingVault) {}

    // ===================================== ADMIN FUNCTIONALITY ========================================

    /**
     * @notice Allows governance to remove the funds in this contract once the airdrop is over.
     *         This function can only be called after the expiration time.
     *
     * @param destination        The address which will receive the remaining tokens
     */
    function reclaim(address destination) external onlyOwner {
        if (block.timestamp <= expiration) revert AA_ClaimingNotExpired();
        if (destination == address(0)) revert AA_ZeroAddress("destination");

        uint256 unclaimed = token.balanceOf(address(this));
        token.safeTransfer(destination, unclaimed);
    }

    /**
     * @notice Allows the owner to set a merkle root and its expiration timestamp. When creating
     *         a merkle trie, a users address should not be associated with multiple leaves.
     *
     * @param _merkleRoot        The new merkle root
     * @param _expiration        The new expiration timestamp for this root
     */
    function setMerkleRoot(bytes32 _merkleRoot, uint256 _expiration) external onlyOwner {
        if (_expiration <= block.timestamp) revert AA_ClaimingExpired();

        rewardsRoot = _merkleRoot;
        expiration = _expiration;

        emit SetMerkleRoot(_merkleRoot, _expiration);
    }
}