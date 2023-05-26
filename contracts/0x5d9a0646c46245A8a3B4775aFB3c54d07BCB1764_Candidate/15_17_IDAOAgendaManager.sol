// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { LibAgenda } from "LibAgenda.sol";
import { IDAOCommittee } from "IDAOCommittee.sol";

interface IDAOAgendaManager  {
    struct Ratio {
        uint256 numerator;
        uint256 denominator;
    }

    function setCommittee(address _committee) external;
    function setCreateAgendaFees(uint256 _createAgendaFees) external;
    function setMinimumNoticePeriodSeconds(uint256 _minimumNoticePeriodSeconds) external;
    function setMinimumVotingPeriodSeconds(uint256 _minimumVotingPeriodSeconds) external;
    function setExecutingPeriodSeconds(uint256 _executingPeriodSeconds) external;
    function newAgenda(
        address[] memory _targets,
        uint256 _noticePeriodSeconds,
        uint256 _votingPeriodSeconds,
        bool _atomicExecute,
        bytes[] calldata _functionBytecodes
    )
        external
        returns (uint256 agendaID);
    function castVote(uint256 _agendaID, address voter, uint256 _vote) external returns (bool);
    function setExecutedAgenda(uint256 _agendaID) external;
    function setResult(uint256 _agendaID, LibAgenda.AgendaResult _result) external;
    function setStatus(uint256 _agendaID, LibAgenda.AgendaStatus _status) external;
    function endAgendaVoting(uint256 _agendaID) external;
    function setExecutedCount(uint256 _agendaID, uint256 _count) external;
     
    // -- view functions
    function isVoter(uint256 _agendaID, address _user) external view returns (bool);
    function hasVoted(uint256 _agendaID, address _user) external view returns (bool);
    function getVoteStatus(uint256 _agendaID, address _user) external view returns (bool, uint256);
    function getAgendaNoticeEndTimeSeconds(uint256 _agendaID) external view returns (uint256);
    function getAgendaVotingStartTimeSeconds(uint256 _agendaID) external view returns (uint256);
    function getAgendaVotingEndTimeSeconds(uint256 _agendaID) external view returns (uint256) ;

    function canExecuteAgenda(uint256 _agendaID) external view returns (bool);
    function getAgendaStatus(uint256 _agendaID) external view returns (uint256 status);
    function totalAgendas() external view returns (uint256);
    function getAgendaResult(uint256 _agendaID) external view returns (uint256 result, bool executed);
    function getExecutionInfo(uint256 _agendaID)
        external
        view
        returns(
            address[] memory target,
            bytes[] memory functionBytecode,
            bool atomicExecute,
            uint256 executeStartFrom
        );
    function isVotableStatus(uint256 _agendaID) external view returns (bool);
    function getVotingCount(uint256 _agendaID)
        external
        view
        returns (
            uint256 countingYes,
            uint256 countingNo,
            uint256 countingAbstain
        );
    function getAgendaTimestamps(uint256 _agendaID)
        external
        view
        returns (
            uint256 createdTimestamp,
            uint256 noticeEndTimestamp,
            uint256 votingStartedTimestamp,
            uint256 votingEndTimestamp,
            uint256 executedTimestamp
        );
    function numAgendas() external view returns (uint256);
    function getVoters(uint256 _agendaID) external view returns (address[] memory);

    function getStatus(uint256 _createAgendaFees) external pure returns (LibAgenda.AgendaStatus);

    // getter
    function committee() external view returns (IDAOCommittee);
    function createAgendaFees() external view returns (uint256);
    function minimumNoticePeriodSeconds() external view returns (uint256);
    function minimumVotingPeriodSeconds() external view returns (uint256);
    function executingPeriodSeconds() external view returns (uint256);
    function agendas(uint256 _index) external view returns (LibAgenda.Agenda memory);
    function voterInfos(uint256 _index1, address _index2) external view returns (LibAgenda.Voter memory);
}