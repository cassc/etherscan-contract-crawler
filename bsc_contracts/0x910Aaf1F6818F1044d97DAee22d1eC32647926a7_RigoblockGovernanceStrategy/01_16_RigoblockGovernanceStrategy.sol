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

import "../../staking/interfaces/IStaking.sol";
import "../../staking/interfaces/IStorage.sol";
import "../IRigoblockGovernance.sol";
import "../interfaces/IGovernanceStrategy.sol";

contract RigoblockGovernanceStrategy is IGovernanceStrategy {
    address private immutable _stakingProxy;
    uint256 private immutable _votingPeriod;

    constructor(address stakingProxy) {
        _stakingProxy = stakingProxy;
        _votingPeriod = 7 days;
    }

    /// @inheritdoc IGovernanceStrategy
    function assertValidInitParams(IRigoblockGovernanceFactory.Parameters memory params) external view override {
        assert(keccak256(abi.encodePacked(params.name)) == keccak256(abi.encodePacked(string("Rigoblock Governance"))));
        assertValidThresholds(params.proposalThreshold, params.quorumThreshold);
    }

    /// @inheritdoc IGovernanceStrategy
    function assertValidThresholds(uint256 proposalThreshold, uint256 quorumThreshold) public view override {
        _assertValidProposalThreshold(proposalThreshold);
        _assertValidQuorumThreshold(quorumThreshold);
    }

    /// @inheritdoc IGovernanceStrategy
    function getProposalState(IRigoblockGovernance.Proposal memory proposal, uint256 minimumQuorum)
        external
        view
        override
        returns (IRigoblockGovernance.ProposalState)
    {
        // notice: because in rigoblock staking we use epochs, the exact start time will never perfectly match the new epoch
        // using timestamps instead of epoch is a safeguard for upgrades, should the staking system get stuck by being unable to finalize.
        if (block.timestamp <= proposal.startBlockOrTime) {
            return IGovernanceState.ProposalState.Pending;
        } else if (block.timestamp <= proposal.endBlockOrTime && _qualifiedConsensus(proposal, minimumQuorum)) {
            return IGovernanceState.ProposalState.Qualified;
        } else if (block.timestamp <= proposal.endBlockOrTime) {
            return IGovernanceState.ProposalState.Active;
        } else if (proposal.votesFor <= 2 * proposal.votesAgainst || proposal.votesFor < minimumQuorum) {
            return IGovernanceState.ProposalState.Defeated;
        } else if (proposal.executed) {
            return IGovernanceState.ProposalState.Executed;
        } else {
            return IGovernanceState.ProposalState.Succeeded;
        }
    }

    function _qualifiedConsensus(IRigoblockGovernance.Proposal memory proposal, uint256 minimumQuorum)
        private
        view
        returns (bool)
    {
        return (3 * proposal.votesFor >
            2 *
                IStaking(_getStakingProxy())
                    .getGlobalStakeByStatus(IStructs.StakeStatus.DELEGATED)
                    .currentEpochBalance &&
            proposal.votesFor >= minimumQuorum);
    }

    /// @inheritdoc IGovernanceStrategy
    function getVotingPower(address account) public view override returns (uint256) {
        return
            IStaking(_getStakingProxy())
                .getOwnerStakeByStatus(account, IStructs.StakeStatus.DELEGATED)
                .currentEpochBalance;
    }

    /// @inheritdoc IGovernanceStrategy
    function votingPeriod() public view override returns (uint256) {
        uint256 stakingEpochDuration = IStorage(_getStakingProxy()).epochDurationInSeconds();
        return stakingEpochDuration < _votingPeriod ? stakingEpochDuration : _votingPeriod;
    }

    /// @inheritdoc IGovernanceStrategy
    function votingTimestamps() public view override returns (uint256 startBlockOrTime, uint256 endBlockOrTime) {
        startBlockOrTime = IStaking(_getStakingProxy()).getCurrentEpochEarliestEndTimeInSeconds();

        // we require voting starts next block to prevent instant upgrade
        startBlockOrTime = block.timestamp >= startBlockOrTime ? block.timestamp + 1 : startBlockOrTime;

        endBlockOrTime = startBlockOrTime + votingPeriod();
    }

    function _assertValidProposalThreshold(uint256 proposalThreshold) private view {
        uint256 grgTotalSupply = IStaking(_getStakingProxy()).getGrgContract().totalSupply();
        uint256 chainId = block.chainid;

        // between 1 and 2% of total supply
        uint256 floor = grgTotalSupply / 100;
        uint256 cap = grgTotalSupply / 50;

        // hard limits on altchains
        if (chainId != 1) {
            floor = floor < 20_000e18 ? 20_000e18 : floor;
            cap = cap < 100_000e18 ? 100_000e18 : cap;
        }

        assert(proposalThreshold >= floor && proposalThreshold <= cap);
    }

    function _assertValidQuorumThreshold(uint256 quorumThreshold) private view {
        uint256 grgTotalSupply = IStaking(_getStakingProxy()).getGrgContract().totalSupply();
        uint256 chainId = block.chainid;

        // between 4 and 10% of total supply
        uint256 floor = grgTotalSupply / 25;
        uint256 cap = grgTotalSupply / 10;

        // hard limits on altchains
        if (chainId != 1) {
            floor = floor < 100_000e18 ? 100_000e18 : floor;
            cap = cap < 400_000e18 ? 400_000e18 : cap;
        }

        assert(quorumThreshold >= floor && quorumThreshold <= cap);
    }

    /// @notice It is more gas efficient at deploy to reading immutable from internal method.
    function _getStakingProxy() private view returns (address) {
        return _stakingProxy;
    }
}