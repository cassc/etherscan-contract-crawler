// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "Ownable.sol";

import { IDAOCommittee } from "IDAOCommittee.sol";
import { IERC20 } from  "IERC20.sol";
import { SafeMath } from "SafeMath.sol";
import { ISeigManager } from "ISeigManager.sol";
import { ICandidate } from "ICandidate.sol";
import { ILayer2 } from "ILayer2.sol";
import { ILayer2Registry } from "ILayer2Registry.sol";
import { ERC165 } from "ERC165.sol";

/// @title Managing a candidate
/// @notice Either a user or layer2 contract can be a candidate
contract Candidate is Ownable, ERC165, ICandidate, ILayer2 {
    using SafeMath for uint256;

    bool public override isLayer2Candidate;
    address public override candidate;
    string public override memo;

    IDAOCommittee public override committee;
    ISeigManager public override seigManager;

    modifier onlyCandidate() {
        if (isLayer2Candidate) {
            ILayer2 layer2 = ILayer2(candidate);
            require(layer2.operator() == msg.sender, "Candidate: sender is not the operator of this contract");
        } else {
            require(candidate == msg.sender, "Candidate: sender is not the candidate of this contract");
        }
        _;
    }

    constructor(
        address _candidate,
        bool _isLayer2Candidate,
        string memory _memo,
        address _committee,
        address _seigManager
    ) 
    {
        require(
            _candidate != address(0)
            || _committee != address(0)
            || _seigManager != address(0),
            "Candidate: input is zero"
        );
        candidate = _candidate;
        isLayer2Candidate = _isLayer2Candidate;
        if (isLayer2Candidate) {
            require(
                ILayer2(candidate).isLayer2(),
                "Candidate: invalid layer2 contract"
            );
        }
        committee = IDAOCommittee(_committee);
        seigManager = ISeigManager(_seigManager);
        memo = _memo;

        _registerInterface(ICandidate(address(this)).isCandidateContract.selector);
    }
    
    /// @notice Set SeigManager contract address
    /// @param _seigManager New SeigManager contract address
    function setSeigManager(address _seigManager) external override onlyOwner {
        require(_seigManager != address(0), "Candidate: input is zero");
        seigManager = ISeigManager(_seigManager);
    }

    /// @notice Set DAOCommitteeProxy contract address
    /// @param _committee New DAOCommitteeProxy contract address
    function setCommittee(address _committee) external override onlyOwner {
        require(_committee != address(0), "Candidate: input is zero");
        committee = IDAOCommittee(_committee);
    }

    /// @notice Set memo
    /// @param _memo New memo on this candidate
    function setMemo(string calldata _memo) external override onlyOwner {
        memo = _memo;
    }

    /// @notice Set DAOCommitteeProxy contract address
    /// @notice Call updateSeigniorage on SeigManager
    /// @return Whether or not the execution succeeded
    function updateSeigniorage() external override returns (bool) {
        require(address(seigManager) != address(0), "Candidate: SeigManager is zero");
        require(
            !isLayer2Candidate,
            "Candidate: you should update seigniorage from layer2 contract"
        );

        return seigManager.updateSeigniorage();
    }

    /// @notice Try to be a member
    /// @param _memberIndex The index of changing member slot
    /// @return Whether or not the execution succeeded
    function changeMember(uint256 _memberIndex)
        external
        override
        onlyCandidate
        returns (bool)
    {
        return committee.changeMember(_memberIndex);
    }

    /// @notice Retire a member
    /// @return Whether or not the execution succeeded
    function retireMember() external override onlyCandidate returns (bool) {
        return committee.retireMember();
    }
    
    /// @notice Vote on an agenda
    /// @param _agendaID The agenda ID
    /// @param _vote voting type
    /// @param _comment voting comment
    function castVote(
        uint256 _agendaID,
        uint256 _vote,
        string calldata _comment
    )
        external
        override
        onlyCandidate
    {
        committee.castVote(_agendaID, _vote, _comment);
    }

    function claimActivityReward()
        external
        override
        onlyCandidate
    {
        address receiver;

        if (isLayer2Candidate) {
            ILayer2 layer2 = ILayer2(candidate);
            receiver = layer2.operator();
        } else {
            receiver = candidate;
        }
        committee.claimActivityReward(receiver);
    }

    /// @notice Checks whether this contract is a candidate contract
    /// @return Whether or not this contract is a candidate contract
    function isCandidateContract() external view override returns (bool) {
        return true;
    }

    function operator() external view override returns (address) { return candidate; }
    function isLayer2() external view override returns (bool) { return true; }
    function currentFork() external view override returns (uint256) { return 1; }
    function lastEpoch(uint256 forkNumber) external view override returns (uint256) { return 1; }
    function changeOperator(address _operator) external override { }

    /// @notice Retrieves the total staked balance on this candidate
    /// @return totalsupply Total staked amount on this candidate
    function totalStaked()
        external
        view
        override
        returns (uint256 totalsupply)
    {
        IERC20 coinage = _getCoinageToken();
        return coinage.totalSupply();
    }

    /// @notice Retrieves the staked balance of the account on this candidate
    /// @param _account Address being retrieved
    /// @return amount The staked balance of the account on this candidate
    function stakedOf(
        address _account
    )
        external
        view
        override
        returns (uint256 amount)
    {
        IERC20 coinage = _getCoinageToken();
        return coinage.balanceOf(_account);
    }

    function _getCoinageToken() internal view returns (IERC20) {
        address c;
        if (isLayer2Candidate) {
            c = candidate;
        } else {
            c = address(this);
        }

        require(c != address(0), "Candidate: coinage is zero");

        return IERC20(seigManager.coinages(c));
    }
}