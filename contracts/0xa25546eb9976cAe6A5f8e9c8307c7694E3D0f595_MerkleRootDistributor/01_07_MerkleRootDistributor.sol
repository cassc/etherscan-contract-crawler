// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";
import {MerkleProof} from "MerkleProof.sol";
import {Ownable} from "Ownable.sol";


/// @title MerkleRootDistributor
/// @notice Allows the DAO to distribute rewards through Merkle Roots
contract MerkleRootDistributor is Ownable {
    using SafeERC20 for IERC20;

    /// @notice Tree of claimable tokens through this contract
    bytes32 public merkleRoot;

    /// @notice Mapping user -> token -> amount to track claimed amounts
    mapping(address => mapping(address => uint256)) public claimed;

    /// @notice Trusted EOAs to update the merkle root
    mapping(address => uint256) public trusted;

    // ================================== Events ===================================

    event TrustedToggled(address indexed eoa, bool trust);
    event Recovered(address indexed token, address indexed to, uint256 amount);
    event RootUpdated(bytes32 root);
    event Claimed(address user, address token, uint256 amount);

    // ================================= Modifiers =================================

    /// @notice Checks whether the `msg.sender` is a trusted address to change the Merkle root of the contract
    modifier onlyTrusted() {
        require(trusted[msg.sender] == 1, "MerkleRootDistributor: caller is not the trusted");
        _;
    }

    // ============================ Constructor ====================================

    constructor() Ownable() {}

    // =========================== Main Function ===================================

    /// @notice Claims reward for a user
    /// @dev Anyone may call this function for anyone else, funds go to destination regardless, it's just a question of
    /// who provides the proof and pays the gas: `msg.sender` is not used in this function
    /// @param user Recipient of tokens
    /// @param token ERC20 claimed
    /// @param amount Amount of tokens that will be sent to the corresponding user
    /// @param merkleProof Array of hashes bridging from leaf (hash of user | token | amount) to Merkle root
    function claim(
        address user,
        address token,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public {
        // Checking root is not NULL
        require(merkleRoot > 0, "MerkleRootDistributor: root is null");

        // Verifying proof
        bytes32 leaf = keccak256(abi.encode(user, token, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "MerkleRootDistributor: invalid proof");

        // Closing reentrancy gate here
        uint256 toSend = amount - claimed[user][token];
        claimed[user][token] = amount;

        // Sending tokens
        IERC20(token).safeTransfer(user, toSend);
        emit Claimed(user, token, toSend);
    }

    // =========================== Governance Functions ============================

    /// @notice Pull reward amount from caller
    function deposit_reward_token(IERC20 token, uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
    }

    /// @notice Adds or removes trusted EOA
    function toggleTrusted(address eoa) external onlyOwner {
        uint256 trustedStatus = 1 - trusted[eoa];
        trusted[eoa] = trustedStatus;
        emit TrustedToggled(eoa, trustedStatus == 1);
    }

    /// @notice Updates Merkle Root
    function updateRoot(bytes32 _root) external onlyTrusted {
        merkleRoot = _root;
        emit RootUpdated(_root);
    }

    /// @notice Recovers any ERC20 token
    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 amountToRecover
    ) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(to, amountToRecover);
        emit Recovered(tokenAddress, to, amountToRecover);
    }

}