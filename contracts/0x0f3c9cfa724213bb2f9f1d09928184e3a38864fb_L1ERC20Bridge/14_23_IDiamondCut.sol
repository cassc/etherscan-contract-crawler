pragma solidity ^0.8;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "../libraries/Diamond.sol";

interface IDiamondCut {
    function proposeDiamondCut(Diamond.FacetCut[] calldata _facetCuts, address _initAddress) external;

    function cancelDiamondCutProposal() external;

    function executeDiamondCutProposal(Diamond.DiamondCutData calldata _diamondCut) external;

    function emergencyFreezeDiamond() external;

    function unfreezeDiamond() external;

    function approveEmergencyDiamondCutAsSecurityCouncilMember(bytes32 _diamondCutHash) external;

    // FIXME: token holders should have the ability to cancel the upgrade

    event DiamondCutProposal(Diamond.FacetCut[] _facetCuts, address _initAddress);

    event DiamondCutProposalCancelation(uint256 currentProposalId, bytes32 indexed proposedDiamondCutHash);

    event DiamondCutProposalExecution(Diamond.DiamondCutData _diamondCut);

    event EmergencyFreeze();

    event Unfreeze(uint256 lastDiamondFreezeTimestamp);

    event EmergencyDiamondCutApproved(
        address indexed _address,
        uint256 currentProposalId,
        uint256 securityCouncilEmergencyApprovals,
        bytes32 indexed proposedDiamondCutHash
    );
}