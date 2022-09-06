// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./MerkleTreeWithHistory.sol";
import "openzeppelin/security/ReentrancyGuard.sol";

interface IVerifier {
  function verifyProof(bytes memory _proof, uint256[6] memory _input) external returns (bool);
}

contract VoidBeta is MerkleTreeWithHistory, ReentrancyGuard {

    error DenominationTooSmall();
    error CommitmentSubmitted();
    error IncorrectValue();
    error FeeExceedsValue();
    error NoteAlreadySpent();
    error MerkleRootNotFound();
    error InvalidWithdrawProof();
    error RecipientPaymentFailed();
    error RelayerPaymentFailed();

    IVerifier public immutable verifier;
    uint256 public denomination;

    mapping(bytes32 => bool) public nullifierHashes;
    // we store all commitments just to prevent accidental deposits with the same commitment
    mapping(bytes32 => bool) public commitments;

    event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);
    event Withdrawal(address to, bytes32 nullifierHash, address indexed relayer, uint256 fee);

    /**
        @dev The constructor
        @param _verifier the address of SNARK verifier for this contract
        @param _hasher the address of MiMC hash contract
        @param _denomination transfer amount for each deposit
    */
    constructor(IVerifier _verifier, IHasher _hasher, uint256 _denomination) MerkleTreeWithHistory(20, _hasher) {
        if (_denomination <= 0) { revert DenominationTooSmall(); }
        verifier = _verifier;
        denomination = _denomination;
    }

    /**
        @dev Deposit funds into the contract. The caller must send (for ETH) or approve (for ERC20) value equal to or `denomination` of this instance.
        @param _commitment the note commitment, which is PedersenHash(nullifier + secret)
    */
    function deposit(bytes32 _commitment) external payable nonReentrant {
        if (commitments[_commitment]) { revert CommitmentSubmitted(); }

        uint32 insertedIndex = _insert(_commitment);
        commitments[_commitment] = true;
        if (msg.value != denomination) { revert IncorrectValue(); }

        emit Deposit(_commitment, insertedIndex, block.timestamp);
    }

    /**
        @dev Withdraw a deposit from the contract. `proof` is a zkSNARK proof data, and input is an array of circuit public inputs
        `input` array consists of:
            - merkle root of all deposits in the contract
            - hash of unique deposit nullifier to prevent double spends
            - the recipient of funds
            - optional fee that goes to the transaction sender (usually a relay)
    */
    function withdraw(
        bytes calldata _proof,
        bytes32 _root,
        bytes32 _nullifierHash,
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) external payable nonReentrant {
        if (_fee > denomination) { revert FeeExceedsValue(); }
        if (nullifierHashes[_nullifierHash]) { revert NoteAlreadySpent(); }
        if (!isKnownRoot(_root)) { revert MerkleRootNotFound(); } // Make sure to use a recent one
        if (!verifier.verifyProof(
            _proof,
            [uint256(_root), uint256(_nullifierHash), uint256(uint160(address(_recipient))), uint256(uint160(address(_relayer))), _fee, _refund]
        )) { revert InvalidWithdrawProof(); }

        nullifierHashes[_nullifierHash] = true;

        (bool success, ) = _recipient.call{ value: denomination - _fee }("");
        if (!success) { revert RecipientPaymentFailed(); }
        if (_fee > 0) {
            (success, ) = _relayer.call{ value: _fee }("");
            if (!success) { revert RelayerPaymentFailed(); }
        }

        emit Withdrawal(_recipient, _nullifierHash, _relayer, _fee);
    }
}