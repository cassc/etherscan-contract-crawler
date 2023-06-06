// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/consumers/SignatureConsumer.sol";
import "../../interfaces/consumers/VoteStatusConsumer.sol";
import "../../libraries/BridgeOperatorsBallot.sol";
import "../../libraries/AddressArrayUtils.sol";
import "../../libraries/IsolatedGovernance.sol";

abstract contract BOsGovernanceRelay is SignatureConsumer, VoteStatusConsumer {
  /// @dev The last the brige operator set info.
  BridgeOperatorsBallot.BridgeOperatorSet internal _lastSyncedBridgeOperatorSetInfo;
  /// @dev Mapping from period index => epoch index => bridge operators vote
  mapping(uint256 => mapping(uint256 => IsolatedGovernance.Vote)) internal _vote;

  /**
   * @dev Returns the synced bridge operator set info.
   */
  function lastSyncedBridgeOperatorSetInfo() external view returns (BridgeOperatorsBallot.BridgeOperatorSet memory) {
    return _lastSyncedBridgeOperatorSetInfo;
  }

  /**
   * @dev Relays votes by signatures.
   *
   * Requirements:
   * - The period of voting is larger than the last synced period.
   * - The arrays are not empty.
   * - The signature signers are in order.
   *
   * @notice Does not store the voter signature into storage.
   *
   */
  function _relayVotesBySignatures(
    BridgeOperatorsBallot.BridgeOperatorSet calldata _ballot,
    Signature[] calldata _signatures,
    uint256 _minimumVoteWeight,
    bytes32 _domainSeperator
  ) internal {
    require(
      (_ballot.period >= _lastSyncedBridgeOperatorSetInfo.period &&
        _ballot.epoch > _lastSyncedBridgeOperatorSetInfo.epoch),
      "BOsGovernanceRelay: query for outdated bridge operator set"
    );
    BridgeOperatorsBallot.verifyBallot(_ballot);
    require(
      !AddressArrayUtils.isEqual(_ballot.operators, _lastSyncedBridgeOperatorSetInfo.operators),
      "BOsGovernanceRelay: bridge operator set is already voted"
    );
    require(_signatures.length > 0, "BOsGovernanceRelay: invalid array length");

    Signature calldata _sig;
    address[] memory _signers = new address[](_signatures.length);
    address _lastSigner;
    bytes32 _hash = BridgeOperatorsBallot.hash(_ballot);
    bytes32 _digest = ECDSA.toTypedDataHash(_domainSeperator, _hash);

    for (uint256 _i = 0; _i < _signatures.length; _i++) {
      _sig = _signatures[_i];
      _signers[_i] = ECDSA.recover(_digest, _sig.v, _sig.r, _sig.s);
      require(_lastSigner < _signers[_i], "BOsGovernanceRelay: invalid order");
      _lastSigner = _signers[_i];
    }

    IsolatedGovernance.Vote storage _v = _vote[_ballot.period][_ballot.epoch];
    uint256 _totalVoteWeight = _sumBridgeVoterWeights(_signers);
    if (_totalVoteWeight >= _minimumVoteWeight) {
      require(_totalVoteWeight > 0, "BOsGovernanceRelay: invalid vote weight");
      _v.status = VoteStatus.Approved;
      _lastSyncedBridgeOperatorSetInfo = _ballot;
      return;
    }

    revert("BOsGovernanceRelay: relay failed");
  }

  /**
   * @dev Returns the weight of the governor list.
   */
  function _sumBridgeVoterWeights(address[] memory _bridgeVoters) internal view virtual returns (uint256);
}