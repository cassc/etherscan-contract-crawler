// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

/// @title  Interface for TpiAirdrop, a contract that allows whitelisted users to claim TPI tokens
/// @notice Whitelisting implemented with MerkleProof library from OpenZeppelin:
///         (https://docs.openzeppelin.com/contracts/4.x/api/utils#MerkleProof)
////        with additional secret parameter since form of airdrop is chosen by the user
interface ITpiAirdrop {
    /// ============ Errors ============

    /// @notice Thrown if address has already claimed
    error AlreadyClaimed(bytes32 leaf);

    /// @notice Thrown if authorization is failed
    error Auth();

    /// @notice Thrown if permit deadline is expired
    error DeadlineExpired();

    /// @notice Thrown if nonce is reused for permit transfer
    error NonceUsed(bytes32 nonce);

    /// @notice Thrown if address/amount are not part of Merkle tree
    error NotInMerkle();

    /// @notice Thrown if initialized with zero input
    error ZeroAddress();

    /// ============ Events ============

    /// @notice Emitted after a successful token claim
    /// @param account recipient of claim
    /// @param leaf leaf hash
    /// @param amount of tokens claimed
    event Claimed(address indexed account, bytes32 leaf, uint256 amount);

    /// ============ Functions ============

    /// @notice Whitelisted claim of ERC20 tokens
    /// @param account recipient of claim
    /// @param amount of tokens claimed
    /// @param nonce secret part
    /// @param proof Merkle proof
    function claim(
        address account,
        uint256 amount,
        uint256 nonce,
        bytes32[] calldata proof
    ) external;

    /// @notice Authorized TPI approve via EIP712 signature
    /// @param account recipient of allowance
    /// @param amount allowance increase
    /// @param deadline timestamp of signature validity
    /// @param v signature of manager
    /// @param r signature of manager
    /// @param s signature of manager
    function permit(
        address account,
        uint256 amount,
        bytes32 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice Restricted function for Merkle root updating
    /// @param _merkeRoot new root
    function setMerkleRoot(bytes32 _merkeRoot) external;
}