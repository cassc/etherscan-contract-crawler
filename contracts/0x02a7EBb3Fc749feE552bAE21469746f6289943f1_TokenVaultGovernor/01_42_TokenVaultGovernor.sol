// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {SettingStorage} from "../libraries/proxy/SettingStorage.sol";
import {GovernorUpgradeable, IGovernorUpgradeable} from "../libraries/openzeppelin/upgradeable/governance/GovernorUpgradeable.sol";
import {GovernorCountingSimpleUpgradeable} from "../libraries/openzeppelin/upgradeable/governance/extensions/GovernorCountingSimpleUpgradeable.sol";
import {GovernorVotesUpgradeable, IVotesUpgradeable} from "../libraries/openzeppelin/upgradeable/governance/extensions/GovernorVotesUpgradeable.sol";
import {GovernorVotesQuorumFractionUpgradeable} from "../libraries/openzeppelin/upgradeable/governance/extensions/GovernorVotesQuorumFractionUpgradeable.sol";
import {Initializable} from "../libraries/openzeppelin/upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "../libraries/openzeppelin/upgradeable/access/OwnableUpgradeable.sol";
import {TokenVaultGovernorLogic} from "../libraries/logic/TokenVaultGovernorLogic.sol";
import {TokenVaultLogic} from "../libraries/logic/TokenVaultLogic.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {IVault} from "../interfaces/IVault.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

contract TokenVaultGovernor is
    SettingStorage,
    Initializable,
    GovernorUpgradeable,
    GovernorCountingSimpleUpgradeable,
    GovernorVotesUpgradeable,
    GovernorVotesQuorumFractionUpgradeable,
    OwnableUpgradeable
{
    /// @notice  gap for reserve, minus 1 if use
    uint256[10] public __gapUint256;
    /// @notice  gap for reserve, minus 1 if use
    uint256[5] public __gapAddress;

     uint256  delay;
     uint256  period;
     uint256  minProposalToken;

    /// @notice vaultToken
    address public vaultToken;

    constructor(address _settings) SettingStorage(_settings) {}

    function initialize(
        address _vaultToken,
        IVotesUpgradeable _veToken,
        uint256 _quorumPercent,
        uint256 _delay,
        uint256 _period,
        uint256 _minProposalToken
    ) public initializer {
        __Governor_init("TokenGovernor");
        delay = _delay;
        period = _period;
        minProposalToken = _minProposalToken;
        vaultToken = _vaultToken;
        __GovernorCountingSimple_init();
        __GovernorVotes_init(_veToken);
        __GovernorVotesQuorumFraction_init(_quorumPercent); // pass Proposal
        __Ownable_init();
    }

    /*
     * Events to track params changes
     */
    event QuorumUpdated(uint256 oldQuorum, uint256 newQuorum);
    event VotingDelayUpdated(uint256 oldVotingDelay, uint256 newVotingDelay);
    event VotingPeriodUpdated(uint256 oldVotingPeriod, uint256 newVotingPeriod);

    function votingDelay()
        public
        view
        override(IGovernorUpgradeable)
        returns (uint256)
    {
        return delay;
    }

    function votingPeriod()
        public
        view
        override(IGovernorUpgradeable)
        returns (uint256)
    {
        return period;
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernorUpgradeable, GovernorVotesQuorumFractionUpgradeable)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function proposalThreshold()
        public
        view
        override(GovernorUpgradeable)
        returns (uint256)
    {
        return minProposalToken;
    }

    function isAgainstVote(uint256 proposalId) external view returns (bool) {
        uint256 againstVotes;
        uint256 forVotes;
        if (state(proposalId) != ProposalState.Defeated) return false;
        (againstVotes, forVotes, ) = proposalVotes(proposalId);
        return quorum(proposalSnapshot(proposalId)) <= againstVotes;
    }

    function cancelNftProposal(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas,
        string memory description
    ) external returns (uint256) {
        //check
        uint256 proposalId = hashProposal(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );
        for (uint256 i = 0; i < targets.length; ++i) {
            if (targets[i] == address(vaultToken)) {
                if (
                    TokenVaultGovernorLogic.validTargetCallFunction(
                        calldatas[i][:4]
                    )
                ) {
                    (
                        address originTarget,
                        ,
                        bytes memory originData
                    ) = TokenVaultGovernorLogic.decodeTargetCallParams(
                            calldatas[i]
                        );
                    (uint256 pId, ) = TokenVaultGovernorLogic
                        .decodeCastVoteData(originData);
                    if (
                        pId > 0 &&
                        IGovernorUpgradeable(originTarget).state(pId) ==
                        ProposalState.Canceled
                    ) {
                        require(
                            TokenVaultLogic.proposalTargetCallValid(
                                DataTypes.VaultProposalTargetCallValidParams({
                                    msgSender: _msgSender(),
                                    vaultToken: vaultToken,
                                    government: address(this),
                                    treasury: IVault(vaultToken).treasury(),
                                    staking: IVault(vaultToken).staking(),
                                    exchange: IVault(vaultToken).exchange(),
                                    target: originTarget,
                                    data: originData
                                })
                            ),
                            Errors.VAULT_NOT_TARGET_CALL
                        );
                        super._cancel(
                            targets,
                            values,
                            calldatas,
                            keccak256(bytes(description))
                        );
                    }
                }
            }
        }
        return 0;
    }

    function proposalExecuteNone() external {}
}