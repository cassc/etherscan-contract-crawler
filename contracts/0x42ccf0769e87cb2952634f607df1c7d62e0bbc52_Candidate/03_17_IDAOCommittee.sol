// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { IStorageStateCommittee } from "IStorageStateCommittee.sol";

interface IDAOCommittee is IStorageStateCommittee {
    //--owner
    function setSeigManager(address _seigManager) external;
    function setCandidatesSeigManager(address[] calldata _candidateContracts, address _seigManager) external;
    function setCandidatesCommittee(address[] calldata _candidateContracts, address _committee) external;
    function setLayer2Registry(address _layer2Registry) external;
    function setAgendaManager(address _agendaManager) external;
    function setCandidateFactory(address _candidateFactory) external;
    function setTon(address _ton) external;
    function setActivityRewardPerSecond(uint256 _value) external;
    function setDaoVault(address _daoVault) external;

    function increaseMaxMember(uint256 _newMaxMember, uint256 _quorum) external;
    function decreaseMaxMember(uint256 _reducingMemberIndex, uint256 _quorum) external;
    function createCandidate(string calldata _memo) external;
    function registerLayer2Candidate(address _layer2, string memory _memo) external;
    function registerLayer2CandidateByOwner(address _operator, address _layer2, string memory _memo) external;
    function changeMember(uint256 _memberIndex) external returns (bool);
    function retireMember() external returns (bool);
    function setMemoOnCandidate(address _candidate, string calldata _memo) external;
    function setMemoOnCandidateContract(address _candidate, string calldata _memo) external;

    function onApprove(
        address owner,
        address spender,
        uint256 tonAmount,
        bytes calldata data
    )
        external
        returns (bool);

    function setQuorum(uint256 _quorum) external;
    function setCreateAgendaFees(uint256 _fees) external;
    function setMinimumNoticePeriodSeconds(uint256 _minimumNoticePeriod) external;
    function setMinimumVotingPeriodSeconds(uint256 _minimumVotingPeriod) external;
    function setExecutingPeriodSeconds(uint256 _executingPeriodSeconds) external;
    function castVote(uint256 _AgendaID, uint256 _vote, string calldata _comment) external;
    function endAgendaVoting(uint256 _agendaID) external;
    function executeAgenda(uint256 _AgendaID) external;
    function setAgendaStatus(uint256 _agendaID, uint256 _status, uint256 _result) external;

    function updateSeigniorage(address _candidate) external returns (bool);
    function updateSeigniorages(address[] calldata _candidates) external returns (bool);
    function claimActivityReward(address _receiver) external;

    function isCandidate(address _candidate) external view returns (bool);
    function totalSupplyOnCandidate(address _candidate) external view returns (uint256);
    function balanceOfOnCandidate(address _candidate, address _account) external view returns (uint256);
    function totalSupplyOnCandidateContract(address _candidateContract) external view returns (uint256);
    function balanceOfOnCandidateContract(address _candidateContract, address _account) external view returns (uint256);
    function candidatesLength() external view returns (uint256);
    function isExistCandidate(address _candidate) external view returns (bool);
    function getClaimableActivityReward(address _candidate) external view returns (uint256);
}