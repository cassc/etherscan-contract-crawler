// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./Proposable.sol";
import "./GroupSystem.sol";


contract ProposableGroupSystem is Proposable, GroupSystem {
    
    struct Proposal{
        uint256 value;
        uint256 groupIndex;
        address proposer;
        uint8 action;
        uint8 minPositive;
        uint8 minNegative;
        uint8 nowPositive;
        uint8 nowNegative;
        int8 result;
        mapping(address => bool) votePool;
    }
    
    mapping(uint256 => Proposal) internal getProposal;
    uint256 private _proposalIndex = 1;
    mapping(uint8 => uint8) private _actionPct;
    mapping(address => mapping( uint8 => uint256 )) internal getAddressProposalIndex;
    uint256 private _voterNumberLimit=0;

    constructor() {}

/*              INTERFACES                */

    
    function setVoterNumberLimit(uint256 limit) internal override {
        _voterNumberLimit=limit;
    }
    
    function getVoterNumberLimit() internal view override returns (uint256) {
        return _voterNumberLimit;
    }

    function isBelowMaxAllowedMembers(uint256 voterNumber) internal view returns (bool) {
        return (_voterNumberLimit==0 || voterNumber<_voterNumberLimit);
    }

    function isActive(uint256 proposalIndex) internal view override returns (bool){
        if(
            getProposal[proposalIndex].minPositive>0
            &&
            getProposal[proposalIndex].result==0
        ){
            return true;
        }
        return false;
    }

    function addProposal(
        address proposedBy,
        uint8 action,
        uint256 groupIndex,
        uint256 value
    ) internal override returns (uint256 proposalIndex, ErrNo errNo){
        (proposalIndex, errNo)=_addProposal(proposedBy, action, groupIndex, value);
    }

    function voteProposal(address voter, address proposedBy, uint8 action,  uint8 decision) internal override returns (int8, ErrNo) {
        uint256 proposalIndex=getAddressProposalIndex[proposedBy][action];
        return _vote(voter, proposalIndex,  decision);
    }

    function voteProposal(address voter, uint256 proposalIndex,  uint8 decision) internal override returns (int8, ErrNo) {
        return _vote(voter, proposalIndex,  decision);
    }

    function removeProposal(address proposedBy, uint8 action) internal override returns (bool) {
        return _deleteProposal(proposedBy, action);
    }

    function beforeAddingMemberToGroup(uint256 groupIndex, address account) internal override view {
        require(isBelowMaxAllowedMembers(getGroupMemberNumber(groupIndex)), "BP09");
    }

/*          ACTIONS MANAGMENT            */

    function isPct(uint256 pct) internal pure override returns (bool) {
        if(pct==0 || pct>100){
            return false;
        }
        return true;
    }
    
    function setActionPct(uint8 action, uint8 pct) internal override returns (bool) {
        if(isPct(pct)==false){
            return false;
        }
        _actionPct[action]=pct;
        return true;
    }

    function getActionPct(uint8 action) internal view override returns (uint8) {
        return _actionPct[action];
    }


/*              PROPOSAL SYSTEM TOOLS                */

    function _getConsensus(uint256 voterNumber, uint8 pct) private pure returns (uint8, uint8) {
        uint8 neg=uint8((voterNumber*(100-pct))/100);
        uint8 pos=uint8(voterNumber-neg);
        if(pos==0){
            pos=1;
        }
        if(neg==0){
            neg=1;
        }
        return (pos,neg);
    }
    
    function _addProposal(
        address proposedBy,
        uint8 action,
        uint256 groupIndex,
        uint256 value
    ) private returns (uint256 proposalIndex, ErrNo errNo) {
        uint256 voterNumber=getGroupMemberNumber(groupIndex);
        if(isGroupMember(groupIndex, proposedBy)==false){
            return (0, ErrNo.BA01);
        }
        if(getAddressProposalIndex[proposedBy][action]!=0){
            return (0, ErrNo.BP03);
        }
        if(voterNumber==0){
            return (0, ErrNo.BP04);
        }
        if(_actionPct[action]==0){
            return (0, ErrNo.BP06);
        }

        proposalIndex=_proposalIndex++;

        (   getProposal[proposalIndex].minPositive,
            getProposal[proposalIndex].minNegative
        )   = _getConsensus(voterNumber, _actionPct[action]);

        getProposal[proposalIndex].value=value;
        getProposal[proposalIndex].groupIndex=groupIndex;
        getProposal[proposalIndex].proposer=proposedBy;
        getProposal[proposalIndex].action=action;
        getAddressProposalIndex[proposedBy][action]=proposalIndex;
        return (proposalIndex, ErrNo.OK);
    }

    function _deleteProposal(uint256 proposalIndex) private returns (bool) {
        address proposedBy=getProposal[proposalIndex].proposer;
        uint8 action=getProposal[proposalIndex].action;
        return _deleteProposal(proposedBy, action, proposalIndex);
    }

    function _deleteProposal(address proposedBy, uint8 action) private returns (bool) {
        uint256 proposalIndex=getAddressProposalIndex[proposedBy][action];
        return _deleteProposal(proposedBy, action, proposalIndex);
    }

    function _deleteProposal(address proposedBy, uint8 action, uint256 proposalIndex) private returns (bool) {
        //some functions could delete proposal multiple times
        //so no revert if proposal not active
        if(isActive(proposalIndex)==false){
            return false;
        }
        // result==1 means proposal has passed, 0 still voting, -1 denied
        if(getProposal[proposalIndex].result==0){
            getProposal[proposalIndex].result=-1;
        }
        getAddressProposalIndex[proposedBy][action]=0;
        return true;
    }

    function _result(uint256 proposalIndex) private returns (int8) {
        if(getProposal[proposalIndex].nowPositive
            >=
            getProposal[proposalIndex].minPositive
        ){
            _deleteProposal(proposalIndex);
            getProposal[proposalIndex].result=1;
            return 1;
        }else if(getProposal[proposalIndex].nowNegative
            >=
            getProposal[proposalIndex].minNegative
        ){
            _deleteProposal(proposalIndex);
            getProposal[proposalIndex].result=-1;
            return -1;
        
        }
        return 0;
    }

    function _vote(address voter, uint256 proposalIndex,  uint8 decision) private returns (int8, ErrNo) {
        if(isGroupMember(getProposal[proposalIndex].groupIndex, voter)==false){
            return (0, ErrNo.BA01);
        }
        if(getProposal[proposalIndex].votePool[voter]==true){
            return (0, ErrNo.BP07);
        }
        if(isActive(proposalIndex)==false){
            return (0, ErrNo.BP01);
        }
        if(decision==1){
            getProposal[proposalIndex].nowPositive++;
        }else if(decision==0){
            getProposal[proposalIndex].nowNegative++;
        }else{
            return (0, ErrNo.BP08);
        }
        
        getProposal[proposalIndex].votePool[voter]=true;

        return (_result(proposalIndex), ErrNo.OK);
    }
    
}
