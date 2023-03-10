// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { VERIFICATION_BYPASS, SnarkProof, Transaction, BoundParams, VerifyingKey, SNARK_SCALAR_FIELD } from "./Globals.sol";

import { Snark } from "./Snark.sol";

/**
 * @title Verifier
 * @author Railgun Contributors
 * @notice Verifies snark proof
 * @dev Functions in this contract statelessly verify proofs, nullifiers and adaptID should be checked in RailgunLogic.
 */
contract Verifier is OwnableUpgradeable {
  // NOTE: The order of instantiation MUST stay the same across upgrades
  // add new variables to the bottom of the list and decrement __gap
  // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading

  // Verifying key set event
  event VerifyingKeySet(uint256 nullifiers, uint256 commitments, VerifyingKey verifyingKey);

  // Nullifiers => Commitments => Verification Key
  mapping(uint256 => mapping(uint256 => VerifyingKey)) private verificationKeys;

  /**
   * @notice Sets verification key
   * @param _nullifiers - number of nullifiers this verification key is for
   * @param _commitments - number of commitments out this verification key is for
   * @param _verifyingKey - verifyingKey to set
   */
  function setVerificationKey(
    uint256 _nullifiers,
    uint256 _commitments,
    VerifyingKey calldata _verifyingKey
  ) public onlyOwner {
    verificationKeys[_nullifiers][_commitments] = _verifyingKey;

    emit VerifyingKeySet(_nullifiers, _commitments, _verifyingKey);
  }

  /**
   * @notice Gets verification key
   * @param _nullifiers - number of nullifiers this verification key is for
   * @param _commitments - number of commitments out this verification key is for
   */
  function getVerificationKey(
    uint256 _nullifiers,
    uint256 _commitments
  ) public view returns (VerifyingKey memory) {
    // Manually add getter so dynamic IC array is included in response
    return verificationKeys[_nullifiers][_commitments];
  }

  /**
   * @notice Calculates hash of transaction bound params for snark verification
   * @param _boundParams - bound parameters
   * @return bound parameters hash
   */
  function hashBoundParams(BoundParams calldata _boundParams) public pure returns (uint256) {
    return uint256(keccak256(abi.encode(_boundParams))) % SNARK_SCALAR_FIELD;
  }

  /**
   * @notice Verifies inputs against a verification key
   * @param _verifyingKey - verifying key to verify with
   * @param _proof - proof to verify
   * @param _inputs - input to verify
   * @return proof validity
   */
  function verifyProof(
    VerifyingKey memory _verifyingKey,
    SnarkProof calldata _proof,
    uint256[] memory _inputs
  ) public view returns (bool) {
    return Snark.verify(_verifyingKey, _proof, _inputs);
  }

  /**
   * @notice Verifies a transaction
   * @param _transaction to verify
   * @return transaction validity
   */
  function verify(Transaction calldata _transaction) public view returns (bool) {
    uint256 nullifiersLength = _transaction.nullifiers.length;
    uint256 commitmentsLength = _transaction.commitments.length;

    // Retrieve verification key
    VerifyingKey memory verifyingKey = verificationKeys[nullifiersLength][commitmentsLength];

    // Check if verifying key is set
    require(verifyingKey.alpha1.x != 0, "Verifier: Key not set");

    // Calculate inputs
    uint256[] memory inputs = new uint256[](2 + nullifiersLength + commitmentsLength);
    inputs[0] = uint256(_transaction.merkleRoot);

    // Hash bound parameters
    inputs[1] = hashBoundParams(_transaction.boundParams);

    // Loop through nullifiers and add to inputs
    for (uint256 i = 0; i < nullifiersLength; i += 1) {
      inputs[2 + i] = uint256(_transaction.nullifiers[i]);
    }

    // Loop through commitments and add to inputs
    for (uint256 i = 0; i < commitmentsLength; i += 1) {
      inputs[2 + nullifiersLength + i] = uint256(_transaction.commitments[i]);
    }

    // Verify snark proof
    bool validity = verifyProof(verifyingKey, _transaction.proof, inputs);

    // Always return true in gas estimation transaction
    // This is so relayer fees can be calculated without needing to compute a proof
    // solhint-disable-next-line avoid-tx-origin
    if (tx.origin == VERIFICATION_BYPASS) {
      return true;
    } else {
      return validity;
    }
  }

  uint256[49] private __gap;
}