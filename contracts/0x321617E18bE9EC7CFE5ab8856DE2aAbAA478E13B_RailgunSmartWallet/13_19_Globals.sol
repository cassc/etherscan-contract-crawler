// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// Constants
uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
// Verification bypass address, can't be address(0) as many burn prevention mechanisms will disallow transfers to 0
// Use 0x000000000000000000000000000000000000dEaD as an alternative known burn address
// https://etherscan.io/address/0x000000000000000000000000000000000000dEaD
address constant VERIFICATION_BYPASS = 0x000000000000000000000000000000000000dEaD;

struct ShieldRequest {
  CommitmentPreimage preimage;
  ShieldCiphertext ciphertext;
}

enum TokenType {
  ERC20,
  ERC721,
  ERC1155
}

struct TokenData {
  TokenType tokenType;
  address tokenAddress;
  uint256 tokenSubID;
}

struct CommitmentCiphertext {
  bytes32[4] ciphertext; // Ciphertext order: IV & tag (16 bytes each), encodedMPK (senderMPK XOR receiverMPK), random & amount (16 bytes each), token
  bytes32 blindedSenderViewingKey;
  bytes32 blindedReceiverViewingKey;
  bytes annotationData; // Only for sender to decrypt
  bytes memo; // Added to note ciphertext for decryption
}

struct ShieldCiphertext {
  bytes32[3] encryptedBundle; // IV shared (16 bytes), tag (16 bytes), random (16 bytes), IV sender (16 bytes), receiver viewing public key (32 bytes)
  bytes32 shieldKey; // Public key to generate shared key from
}

enum UnshieldType {
  NONE,
  NORMAL,
  REDIRECT
}

struct BoundParams {
  uint16 treeNumber;
  uint72 minGasPrice; // Only for type 0 transactions
  UnshieldType unshield;
  uint64 chainID;
  address adaptContract;
  bytes32 adaptParams;
  // For unshields do not include an element in ciphertext array
  // Ciphertext array length = commitments - unshields
  CommitmentCiphertext[] commitmentCiphertext;
}

struct Transaction {
  SnarkProof proof;
  bytes32 merkleRoot;
  bytes32[] nullifiers;
  bytes32[] commitments;
  BoundParams boundParams;
  CommitmentPreimage unshieldPreimage;
}

struct CommitmentPreimage {
  bytes32 npk; // Poseidon(Poseidon(spending public key, nullifying key), random)
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

struct VerifyingKey {
  string artifactsIPFSHash;
  G1Point alpha1;
  G2Point beta2;
  G2Point gamma2;
  G2Point delta2;
  G1Point[] ic;
}

struct SnarkProof {
  G1Point a;
  G2Point b;
  G1Point c;
}