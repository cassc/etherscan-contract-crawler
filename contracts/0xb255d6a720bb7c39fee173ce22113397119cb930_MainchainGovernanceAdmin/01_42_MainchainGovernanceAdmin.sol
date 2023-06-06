// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../extensions/bridge-operator-governance/BOsGovernanceRelay.sol";
import "../extensions/sequential-governance/GovernanceRelay.sol";
import "../extensions/TransparentUpgradeableProxyV2.sol";
import "../extensions/GovernanceAdmin.sol";
import "../interfaces/IBridge.sol";

contract MainchainGovernanceAdmin is AccessControlEnumerable, GovernanceRelay, GovernanceAdmin, BOsGovernanceRelay {
  bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
  uint256 private constant DEFAULT_EXPIRY_DURATION = 1 << 255;

  constructor(
    uint256 _roninChainId,
    address _roleSetter,
    address _roninTrustedOrganizationContract,
    address _bridgeContract,
    address[] memory _relayers
  ) GovernanceAdmin(_roninChainId, _roninTrustedOrganizationContract, _bridgeContract, DEFAULT_EXPIRY_DURATION) {
    _setupRole(DEFAULT_ADMIN_ROLE, _roleSetter);
    for (uint256 _i; _i < _relayers.length; _i++) {
      _grantRole(RELAYER_ROLE, _relayers[_i]);
    }
  }

  /**
   * @dev Returns whether the voter `_voter` casted vote for the proposal.
   */
  function proposalRelayed(uint256 _chainId, uint256 _round) external view returns (bool) {
    return vote[_chainId][_round].status != VoteStatus.Pending;
  }

  /**
   * @dev Returns whether the voter `_voter` casted vote for bridge operators at a specific period.
   */
  function bridgeOperatorsRelayed(uint256 _period, uint256 _epoch) external view returns (bool) {
    return _vote[_period][_epoch].status != VoteStatus.Pending;
  }

  /**
   * @dev See `GovernanceRelay-_relayProposal`.
   *
   * Requirements:
   * - The method caller is relayer.
   *
   */
  function relayProposal(
    Proposal.ProposalDetail calldata _proposal,
    Ballot.VoteType[] calldata _supports,
    Signature[] calldata _signatures
  ) external onlyRole(RELAYER_ROLE) {
    _relayProposal(_proposal, _supports, _signatures, DOMAIN_SEPARATOR, msg.sender);
  }

  /**
   * @dev See `GovernanceRelay-_relayGlobalProposal`.
   *
   * Requirements:
   * - The method caller is relayer.
   *
   */
  function relayGlobalProposal(
    GlobalProposal.GlobalProposalDetail calldata _globalProposal,
    Ballot.VoteType[] calldata _supports,
    Signature[] calldata _signatures
  ) external onlyRole(RELAYER_ROLE) {
    _relayGlobalProposal(
      _globalProposal,
      _supports,
      _signatures,
      DOMAIN_SEPARATOR,
      roninTrustedOrganizationContract(),
      bridgeContract(),
      msg.sender
    );
  }

  /**
   * @dev See `BOsGovernanceRelay-_relayVotesBySignatures`.
   *
   * Requirements:
   * - The method caller is relayer.
   *
   */
  function relayBridgeOperators(
    BridgeOperatorsBallot.BridgeOperatorSet calldata _ballot,
    Signature[] calldata _signatures
  ) external onlyRole(RELAYER_ROLE) {
    _relayVotesBySignatures(_ballot, _signatures, _getMinimumVoteWeight(), DOMAIN_SEPARATOR);
    TransparentUpgradeableProxyV2(payable(bridgeContract())).functionDelegateCall(
      abi.encodeWithSelector(_bridgeContract.replaceBridgeOperators.selector, _ballot.operators)
    );
  }

  /**
   * @inheritdoc GovernanceRelay
   */
  function _sumWeights(address[] memory _governors) internal view virtual override returns (uint256) {
    bytes4 _selector = IRoninTrustedOrganization.sumGovernorWeights.selector;
    (bool _success, bytes memory _returndata) = roninTrustedOrganizationContract().staticcall(
      abi.encodeWithSelector(
        // TransparentUpgradeableProxyV2.functionDelegateCall.selector,
        0x4bb5274a,
        abi.encodeWithSelector(_selector, _governors)
      )
    );
    if (!_success) revert ErrProxyCallFailed(_selector);
    return abi.decode(_returndata, (uint256));
  }

  /**
   * @inheritdoc BOsGovernanceRelay
   */
  function _sumBridgeVoterWeights(address[] memory _governors) internal view virtual override returns (uint256) {
    bytes4 _selector = IRoninTrustedOrganization.sumBridgeVoterWeights.selector;
    (bool _success, bytes memory _returndata) = roninTrustedOrganizationContract().staticcall(
      abi.encodeWithSelector(
        // TransparentUpgradeableProxyV2.functionDelegateCall.selector,
        0x4bb5274a,
        abi.encodeWithSelector(_selector, _governors)
      )
    );
    if (!_success) revert ErrProxyCallFailed(_selector);
    return abi.decode(_returndata, (uint256));
  }

  /**
   * @dev See {CoreGovernance-_getChainType}
   */
  function _getChainType() internal pure override returns (ChainType) {
    return ChainType.Mainchain;
  }
}