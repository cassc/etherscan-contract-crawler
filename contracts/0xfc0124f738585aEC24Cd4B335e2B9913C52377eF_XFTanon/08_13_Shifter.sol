// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Interfaces/IStorage.sol";
import "./MerkleTreeWithHistory.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IVerifier {
  function verifyProof(bytes memory _proof, uint256[6] memory _input) external returns (bool);
}

abstract contract Shifter is MerkleTreeWithHistory, ReentrancyGuard {
  IVerifier public immutable verifier;
  IStorage public immutable noteStorage;
  uint256 public immutable denomination;
  uint256 public immutable ethDenomination;
  bytes32[] public allCommitments;

  mapping(bytes32 => bool) public nullifierHashes;
  // we store all commitments just to prevent accidental deposits with the same commitment
  mapping(bytes32 => bool) public commitments;

  event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp, address indexed depositor, uint256 ethDenomination, uint256 denomination);
  event Withdrawal(address to, bytes32 nullifierHash, address indexed relayer, uint256 fee);

  /**
    @dev The constructor
    @param _verifier the address of SNARK verifier for this contract
    @param _hasher the address of MiMC hash contract
    @param _storage the address of the storage contract
    @param _denomination transfer amount for each deposit
    @param _merkleTreeHeight the height of deposits' Merkle Tree
    @param _ethDenomination the amount of ETH to be deposted
  */
  constructor(
    IVerifier _verifier,
    IHasher _hasher,
    IStorage _storage,
    uint256 _denomination,
    uint256 _ethDenomination,
    uint32 _merkleTreeHeight
  ) MerkleTreeWithHistory(_merkleTreeHeight, _hasher) {
    require(_denomination > 0, "denomination should be greater than 0");
    noteStorage = _storage;
    verifier = _verifier;
    denomination = _denomination;
    ethDenomination = _ethDenomination;
  }
  
  /**
    @dev Return the entire commitment array
   */
  function commitmentList() public view returns (bytes32[] memory) {
    return allCommitments;
  }

  /**
    @dev Return the length of the commitment array
   */
  function commitmentListLength() public view returns (uint256) {
    return allCommitments.length;
  }

  /**
    @dev Deposit funds into the contract. The caller must send (for ETH) or approve (for ERC20) value equal to or `denomination` of this instance.
    @param _commitment the note commitment, which is PedersenHash(nullifier + secret)
    @param _encryptedNote encrypted preimage, use xcrypt view for symmetrical encryption (unchecked)
    @param _passwordHash the hash of the password (unchecked)
  */
  function deposit(bytes32 _commitment, bytes calldata _encryptedNote, bytes32 _passwordHash) external payable nonReentrant {
    require(msg.value == ethDenomination, "Incorrect deposit value"); // Require fee for gas
    require(!commitments[_commitment], "The commitment has been submitted");
    uint32 insertedIndex = _insert(_commitment);
    allCommitments.push(_commitment);
    noteStorage.store(msg.sender, _encryptedNote, _passwordHash);
    commitments[_commitment] = true;
    _processDeposit();

    emit Deposit(_commitment, insertedIndex, block.timestamp, msg.sender, msg.value, denomination);
  }

  /** @dev this function is defined in a child contract */
  function _processDeposit() internal virtual;

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
    require(_fee <= denomination, "Fee exceeds transfer value");
    require(!nullifierHashes[_nullifierHash], "The note has been already spent");
    require(isKnownRoot(_root), "Cannot find your merkle root"); // Make sure to use a recent one
    require(
      verifier.verifyProof(
        _proof,
        [uint256(_root), uint256(_nullifierHash), uint256(_recipient), uint256(_relayer), _fee, _refund]
      ),
      "Invalid withdraw proof"
    );

    nullifierHashes[_nullifierHash] = true;
    _processWithdraw(_recipient, _relayer, _fee, _refund);
    emit Withdrawal(_recipient, _nullifierHash, _relayer, _fee);
  }

  /** @dev this function is defined in a child contract */
  function _processWithdraw(
    address payable _recipient,
    address payable _relayer,
    uint256 _fee,
    uint256 _refund
  ) internal virtual;

  /** @dev whether a note is already spent */
  function isSpent(bytes32 _nullifierHash) public view returns (bool) {
    return nullifierHashes[_nullifierHash];
  }

  /** @dev whether an array of notes is already spent */
  function isSpentArray(bytes32[] calldata _nullifierHashes) external view returns (bool[] memory spent) {
    uint256 nullifierHashesLength = _nullifierHashes.length;
    spent = new bool[](nullifierHashesLength);
    for (uint256 i; i < nullifierHashesLength; i++) {
      if (isSpent(_nullifierHashes[i])) { 
        spent[i] = true;
      }
    }
  }
}