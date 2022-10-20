pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



import "../interfaces/IDiamondCut.sol";
import "../libraries/Diamond.sol";
import "../Config.sol";
import "./Base.sol";

/// @title DiamondCut contract responsible for the management of upgrades.
/// @author Matter Labs
contract DiamondCutFacet is Base, IDiamondCut {
    constructor() {
        // Caution check for config value.
        // Should be greater than 0, otherwise zero approvals will be enough to make an instant upgrade!
        assert(SECURITY_COUNCIL_APPROVALS_FOR_EMERGENCY_UPGRADE > 0);
    }

    /// @dev Starts the upgrade process. Only the current governor can propose an upgrade.
    /// @param _facetCuts The set of proposed changes to the facets (adding/replacement/removing)
    /// @param _initAddress Address of the fallback contract that will be called after the upgrade execution
    function proposeDiamondCut(Diamond.FacetCut[] calldata _facetCuts, address _initAddress) external onlyGovernor {
        require(s.diamondCutStorage.proposedDiamondCutTimestamp == 0, "a3"); // proposal already exists

        // NOTE: governor commits only to the `facetCuts` and `initAddress`, but not to the calldata on `initAddress` call.
        // That means the governor can call `initAddress` with ANY calldata while executing the upgrade.
        s.diamondCutStorage.proposedDiamondCutHash = keccak256(abi.encode(_facetCuts, _initAddress));
        s.diamondCutStorage.proposedDiamondCutTimestamp = block.timestamp;
        s.diamondCutStorage.currentProposalId += 1;

        emit DiamondCutProposal(_facetCuts, _initAddress);
    }

    /// @notice Removes the upgrade proposal. Only current governor can remove proposal.
    function cancelDiamondCutProposal() external onlyGovernor {
        emit DiamondCutProposalCancelation(
            s.diamondCutStorage.currentProposalId,
            s.diamondCutStorage.proposedDiamondCutHash
        );
        require(_resetProposal(), "g1"); // failed cancel diamond cut
    }

    /// @notice Executes a proposed governor upgrade. Only the current governor can execute the upgrade.
    /// NOTE: Governor can execute diamond cut ONLY with proposed `facetCuts` and `initAddress`.
    /// `initCalldata` can be arbitrarily.
    function executeDiamondCutProposal(Diamond.DiamondCutData calldata _diamondCut) external onlyGovernor {
        Diamond.DiamondStorage storage diamondStorage = Diamond.getDiamondStorage();

        bool approvedBySecurityCouncil = s.diamondCutStorage.securityCouncilEmergencyApprovals >=
            SECURITY_COUNCIL_APPROVALS_FOR_EMERGENCY_UPGRADE;

        bool upgradeNoticePeriodPassed = block.timestamp >=
            s.diamondCutStorage.proposedDiamondCutTimestamp + UPGRADE_NOTICE_PERIOD;

        require(approvedBySecurityCouncil || upgradeNoticePeriodPassed, "a6"); // notice period should expire
        require(approvedBySecurityCouncil || !diamondStorage.isFrozen, "f3");
        // should not be frozen or should have enough security council approvals

        require(
            s.diamondCutStorage.proposedDiamondCutHash ==
                keccak256(abi.encode(_diamondCut.facetCuts, _diamondCut.initAddress)),
            "a4"
        ); // proposal should be created

        require(_resetProposal(), "a5"); // failed reset proposal

        if (diamondStorage.isFrozen) {
            diamondStorage.isFrozen = false;
            emit Unfreeze(s.diamondCutStorage.lastDiamondFreezeTimestamp);
        }

        Diamond.diamondCut(_diamondCut);

        emit DiamondCutProposalExecution(_diamondCut);
    }

    /// @notice Instantly pause the functionality of all freezable facets & their selectors
    function emergencyFreezeDiamond() external onlyGovernor {
        Diamond.DiamondStorage storage diamondStorage = Diamond.getDiamondStorage();
        require(!diamondStorage.isFrozen, "a9"); // diamond proxy is frozen already
        _resetProposal();

        diamondStorage.isFrozen = true;
        // Limited-time freezing feature will be added in the future upgrades, so keeping this variable for simplification
        s.diamondCutStorage.lastDiamondFreezeTimestamp = block.timestamp;

        emit EmergencyFreeze();
    }

    /// @notice Unpause the functionality of all freezable facets & their selectors
    function unfreezeDiamond() external onlyGovernor {
        Diamond.DiamondStorage storage diamondStorage = Diamond.getDiamondStorage();

        require(diamondStorage.isFrozen, "a7"); // diamond proxy is not frozen

        _resetProposal();

        diamondStorage.isFrozen = false;

        emit Unfreeze(s.diamondCutStorage.lastDiamondFreezeTimestamp);
    }

    /// @notice Gives another approval for the instant upgrade (diamond cut) by the security council member
    /// @param _diamondCutHash The hash of the diamond cut that security council members want to approve. Needed to prevent unintentional approvals, including reorg attacks
    function approveEmergencyDiamondCutAsSecurityCouncilMember(bytes32 _diamondCutHash) external {
        require(s.diamondCutStorage.securityCouncilMembers[msg.sender], "a9"); // not a security council member
        uint256 currentProposalId = s.diamondCutStorage.currentProposalId;
        require(s.diamondCutStorage.securityCouncilMemberLastApprovedProposalId[msg.sender] < currentProposalId, "ao"); // already approved this proposal
        s.diamondCutStorage.securityCouncilMemberLastApprovedProposalId[msg.sender] = currentProposalId;

        require(s.diamondCutStorage.proposedDiamondCutTimestamp != 0, "f0"); // there is no proposed diamond cut
        require(s.diamondCutStorage.proposedDiamondCutHash == _diamondCutHash, "f1"); // proposed diamond cut do not match to the approved
        uint256 securityCouncilEmergencyApprovals = s.diamondCutStorage.securityCouncilEmergencyApprovals;
        s.diamondCutStorage.securityCouncilEmergencyApprovals = securityCouncilEmergencyApprovals + 1;

        emit EmergencyDiamondCutApproved(
            msg.sender,
            currentProposalId,
            securityCouncilEmergencyApprovals,
            _diamondCutHash
        );
    }

    /// @dev Set up the proposed diamond cut state to the default values
    /// @return Whether the proposal is reset or it was already empty
    function _resetProposal() private returns (bool) {
        if (s.diamondCutStorage.proposedDiamondCutTimestamp == 0) {
            return false;
        }

        delete s.diamondCutStorage.proposedDiamondCutHash;
        delete s.diamondCutStorage.proposedDiamondCutTimestamp;
        delete s.diamondCutStorage.securityCouncilEmergencyApprovals;

        return true;
    }
}