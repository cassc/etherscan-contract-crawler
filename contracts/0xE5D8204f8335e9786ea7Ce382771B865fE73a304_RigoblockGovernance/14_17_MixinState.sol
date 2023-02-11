// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2023 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

import "./MixinAbstract.sol";
import "./MixinStorage.sol";
import "../interfaces/IGovernanceStrategy.sol";

abstract contract MixinState is MixinStorage, MixinAbstract {
    /// @inheritdoc IGovernanceState
    function getActions(uint256 proposalId) external view override returns (ProposedAction[] memory proposedActions) {
        Proposal memory proposal = _proposal().proposalById[proposalId];
        uint256 actionsLength = proposal.actionsLength;
        proposedActions = new ProposedAction[](actionsLength);
        for (uint256 i = 0; i < actionsLength; i++) {
            proposedActions[i] = _proposedAction().proposedActionbyIndex[proposalId][i];
        }
    }

    /// @inheritdoc IGovernanceState
    function getProposalState(uint256 proposalId) external view override returns (ProposalState) {
        return _getProposalState(proposalId);
    }

    /// @inheritdoc IGovernanceState
    function getReceipt(uint256 proposalId, address voter) external view override returns (Receipt memory) {
        return _receipt().userReceiptByProposal[proposalId][voter];
    }

    /// @inheritdoc IGovernanceState
    function getVotingPower(address account) external view override returns (uint256) {
        return _getVotingPower(account);
    }

    /// @inheritdoc IGovernanceState
    function governanceParameters() external view override returns (EnhancedParams memory) {
        return EnhancedParams({params: _paramsWrapper().governanceParameters, name: _name().value, version: VERSION});
    }

    /// @inheritdoc IGovernanceState
    function name() external view override returns (string memory) {
        return _name().value;
    }

    /// @inheritdoc IGovernanceState
    function proposalCount() external view override returns (uint256 count) {
        return _getProposalCount();
    }

    /// @inheritdoc IGovernanceState
    function proposals() external view override returns (ProposalWrapper[] memory proposalWrapper) {
        uint256 length = _getProposalCount();
        proposalWrapper = new ProposalWrapper[](length);
        for (uint256 i = 0; i < length; i++) {
            // proposal count starts at proposalId = 1
            proposalWrapper[i] = getProposalById(i + 1);
        }
    }

    /// @inheritdoc IGovernanceState
    function votingPeriod() external view override returns (uint256) {
        return IGovernanceStrategy(_governanceParameters().strategy).votingPeriod();
    }

    /// @inheritdoc IGovernanceState
    function getProposalById(uint256 proposalId) public view override returns (ProposalWrapper memory proposalWrapper) {
        proposalWrapper.proposal = _proposal().proposalById[proposalId];
        uint256 actionsLength = proposalWrapper.proposal.actionsLength;
        ProposedAction[] memory proposedAction = new ProposedAction[](actionsLength);
        for (uint256 i = 0; i < actionsLength; i++) {
            proposedAction[i] = _proposedAction().proposedActionbyIndex[proposalId][i];
        }
        proposalWrapper.proposedAction = proposedAction;
    }

    function _getProposalCount() internal view override returns (uint256 count) {
        return _proposalCount().value;
    }

    function _getProposalState(uint256 proposalId) internal view override returns (ProposalState) {
        require(_proposalCount().value >= proposalId && proposalId > 0, "VOTING_PROPOSAL_ID_ERROR");
        Proposal memory proposal = _proposal().proposalById[proposalId];
        return
            IGovernanceStrategy(_governanceParameters().strategy).getProposalState(
                proposal,
                _governanceParameters().quorumThreshold
            );
    }

    function _getVotingPower(address account) internal view override returns (uint256) {
        return IGovernanceStrategy(_governanceParameters().strategy).getVotingPower(account);
    }
}