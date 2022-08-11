// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// Constants
uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
uint256 constant CIPHERTEXT_WORDS = 4;

enum TokenType { ERC20, ERC721, ERC1155 }

// Transaction token data
struct TokenData {
  TokenType tokenType;
  address tokenAddress;
  uint256 tokenSubID;
}

// Commitment ciphertext
struct CommitmentCiphertext {
  uint256[CIPHERTEXT_WORDS] ciphertext; // Ciphertext order: iv & tag (16 bytes each), recipient master public key (packedPoint) (uint256), packedField (uint256) {sign, random, amount}, token (uint256)
  uint256[2] ephemeralKeys; // Sender first, receipient second (packed points 32 bytes each)
  uint256[] memo;
}

enum WithdrawType { NONE, WITHDRAW, REDIRECT }

// Transaction bound parameters
struct BoundParams {
  uint16 treeNumber;
  WithdrawType withdraw;
  address adaptContract;
  bytes32 adaptParams;
  // For withdraws do not include an element in ciphertext array
  // Ciphertext array length = commitments - withdraws
  CommitmentCiphertext[] commitmentCiphertext;
}

// Transaction struct
struct Transaction {
  SnarkProof proof;
  uint256 merkleRoot;
  uint256[] nullifiers;
  uint256[] commitments;
  BoundParams boundParams;
  CommitmentPreimage withdrawPreimage;
  address overrideOutput; // Only allowed if original destination == msg.sender & boundParams.withdraw == 2
}

// Commitment hash preimage
struct CommitmentPreimage {
  uint256 npk; // Poseidon(mpk, random), mpk = Poseidon(spending public key, nullifier)
  TokenData token; // Token field
  uint120 value; // Note value
}

struct G1Point {
  uint256 x;
  uint256 y;
}

// Encoding of field elements is: X[0] * z + X[1]
struct G2Point {
  uint256[2] x;
  uint256[2] y;
}

// Verification key for SNARK
struct VerifyingKey {
  string artifactsIPFSHash;
  G1Point alpha1;
  G2Point beta2;
  G2Point gamma2;
  G2Point delta2;
  G1Point[] ic;
}

// Snark proof for transaction
struct SnarkProof {
  G1Point a;
  G2Point b;
  G1Point c;
}