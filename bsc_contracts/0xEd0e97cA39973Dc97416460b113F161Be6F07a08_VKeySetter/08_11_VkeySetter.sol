// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Delegator } from "./Delegator.sol";
import { Verifier, VerifyingKey } from "../logic/Verifier.sol";

/**
 * @title VKeySetter
 * @author Railgun Contributors
 * @notice
 */
contract VKeySetter is Ownable {
  Delegator public delegator;
  Verifier public verifier;

  // Lock adding new vKeys once this boolean is flipped
  enum VKeySetterState {
    SETTING,
    WAITING,
    COMMITTING
  }

  VKeySetterState public state;

  // Nullifiers => Commitments => Verification Key
  mapping(uint256 => mapping(uint256 => VerifyingKey)) private verificationKeys;

  // Owner can set vKeys in setting state
  // Owner can always change contract to waiting state
  // Governance is required to change state to committing state
  // Owner can only change contract to setting state when in committing state

  modifier onlySetting() {
    require(state == VKeySetterState.SETTING, "VKeySetter: Contract is not in setting state");
    _;
  }

  // modifier onlyWaiting() {
  //   require(state == VKeySetterState.WAITING, "VKeySetter: Contract is not in waiting state");
  //   _;
  // }

  modifier onlyCommitting() {
    require(state == VKeySetterState.COMMITTING, "VKeySetter: Contract is not in committing state");
    _;
  }

  modifier onlyDelegator() {
    require(msg.sender == address(delegator), "VKeySetter: Caller isn't governance");
    _;
  }

  /**
   * @notice Sets initial admin and delegator and verifier contract addresses
   */
  constructor(address _admin, Delegator _delegator, Verifier _verifier) {
    Ownable.transferOwnership(_admin);
    delegator = _delegator;
    verifier = _verifier;
  }

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
  ) public onlyOwner onlySetting {
    verificationKeys[_nullifiers][_commitments] = _verifyingKey;
  }

  /**
   * @notice Gets verification key
   * @param _nullifiers - number of nullifiers this verification key is for
   * @param _commitments - number of commitments out this verification key is for
   */
  function getVerificationKey(
    uint256 _nullifiers,
    uint256 _commitments
  ) external view returns (VerifyingKey memory) {
    // Manually add getter so dynamic IC array is included in response
    return verificationKeys[_nullifiers][_commitments];
  }

  /**
   * @notice Sets verification key
   * @param _nullifiers - array of nullifier values of keys
   * @param _commitments - array of commitment values of keys
   * @param _verifyingKey - array of keys
   */
  function batchSetVerificationKey(
    uint256[] calldata _nullifiers,
    uint256[] calldata _commitments,
    VerifyingKey[] calldata _verifyingKey
  ) external {
    for (uint256 i = 0; i < _nullifiers.length; i += 1) {
      setVerificationKey(_nullifiers[i], _commitments[i], _verifyingKey[i]);
    }
  }

  /**
   * @notice Commits verification keys to contract
   * @param _nullifiers - number of nullifiers this verification key is for
   * @param _commitments - number of commitments out this verification key is for
   */
  function commitVerificationKey(
    uint256 _nullifiers,
    uint256 _commitments
  ) public onlyOwner onlyCommitting {
    // NOTE: The vkey configuration must EXACTLY match the desired vkey configuration on the verifier contract
    // Leaving a vkey empty on this contract can be used to delete a vkey on the verifier contract by setting
    // the values to 0

    delegator.callContract(
      address(verifier),
      abi.encodeWithSelector(
        Verifier.setVerificationKey.selector,
        _nullifiers,
        _commitments,
        verificationKeys[_nullifiers][_commitments]
      ),
      0
    );
  }

  /**
   * @notice Commits verification keys to contract as batch
   * @param _nullifiers - array of nullifier values of keys
   * @param _commitments - array of commitment values of keys
   */
  function batchCommitVerificationKey(
    uint256[] calldata _nullifiers,
    uint256[] calldata _commitments
  ) external {
    for (uint256 i = 0; i < _nullifiers.length; i += 1) {
      commitVerificationKey(_nullifiers[i], _commitments[i]);
    }
  }

  /**
   * @notice Set state to 'setting'
   */
  function stateToSetting() external onlyOwner onlyCommitting {
    state = VKeySetterState.SETTING;
  }

  /**
   * @notice Set state to 'waiting'
   */
  function stateToWaiting() external onlyOwner {
    state = VKeySetterState.WAITING;
  }

  /**
   * @notice Set state to 'committing'
   */
  function stateToCommitting() external onlyDelegator {
    state = VKeySetterState.COMMITTING;
  }
}