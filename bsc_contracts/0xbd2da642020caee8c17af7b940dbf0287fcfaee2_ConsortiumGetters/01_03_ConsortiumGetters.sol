pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;
// SPDX-License-Identifier: MIT

// BNB Smart Chain Testnet: 0x265ad891Fb4daD5BbFE9BD3290D02D1B01d0348C
// BNB Smart Chain Mainnet: 0xBD2dA642020caEE8c17aF7b940DBf0287fCfAEe2

import "./ConsortiumData.sol";

// This contract must be set as the delegated IoVGC contract to call functions from the delegator contract.
contract ConsortiumGetters is ConsortiumData {
    //****************************************************************************
    //* Getter Functions
    //****************************************************************************
// Call this function to get the number of the consortium members.
// Output(s):
//     -Returns the number of the consortium members.
    function getMembersCount() public view returns(uint24) {
        return(membersCount);
    }

// Call this function to determine if the caller account is member of the IoVGC consortium.
// Output(s):
//     -Returns true if the caller account is member of the consortium, otherwise false.
    function AmIMember() public view returns(bool) {
        return(members[msg.sender].isMember);
    }

// Call this function to get an IoVGC consortium member specifications giving the specified member id.
// Input(s):
//     _memberId: The member id. Member id is an ordinal number starting with 0.
// Output(s):
//     _name: The name of the specified member.
//     _memberAddress: The address of the specified member.
    function getMemberById(uint _memberId) public view returns(string memory _name, address _memberAddress) {
        require(_memberId < memberAddresses.length, message12);
        _memberAddress = memberAddresses[_memberId];
        require(_memberAddress != address(0) && members[_memberAddress].isMember, message12);
        _name = members[_memberAddress].name;
    }

// Call this function to get an IoVGC consortium member specifications giving the specified member address.
// Input(s):
//     _memberId: The member id. Member id is an ordinal number starting with 0.
// Output(s):
//     _name: The name of the specified member.
//     _memberId: The id of the specified member.
    function getMemberByAddress(address _memberAddress) public view returns(string memory _name, uint24 _memberId) {
        require(_memberAddress != address(0) && members[_memberAddress].isMember, "Invalid member address.");
        _name = members[_memberAddress].name;
        _memberId = members[_memberAddress].id;
    }

// Call this function to get the number of the offered proposals.
// Note that if you get n as the output of this function, then you can use 0 to n-1 as the proposal id in another functions.
// Output(s):
//     -Returns the number of the offered proposals.
    function getProposalsCount() public view returns(uint) {
        return(proposals.length);
    }

// Call this function to get a specified proposal specifications give its id.
// Input(s):
//     _proposalId: The propsal id: an ordinal number starting with 0.
// Output(s):
//     _approved: The state of theproposal approval: 
//         1: Voting state, 2: Approved, 3: Rejected, 4: Expired
//     _approversCount: The number of approvers member.
//     _rejectorsCount: The number of rejectors member.
//     _pType: The type of the proposal:
//         1: Add Member, 2: Remove Member, 3: Pay IoVT, 4: Pay Token, 5: Pay BNB, 6: Approve Pay IoVT, 7: Pay Delegated IoVT,
//         11: Change Consortium (Transfer Members), 12: Only Change Consortium, 13: Block Account, 14: Unblock Account, 
//         15: Free Voting, 16: Send Data, 17: Change Distributor Target Address, 18: Change DistributorOwner
//     _dscription: The description about the proposal.
// Based of each proposal type another outputs may be reflect these information:
//     1: Add Member
//         _name: The name of the proposed new member.
//         _account: The account address of the proposed new member.
//     2: Remove Member
//         _account: The account address of the proposed member to be removed.
//     3: Pay IoVT
//         _account: the account or smart contract address you want to pay IoVT token pay to.
//         _value: the amount of IoVT token you want to pay. (trailing zeros for the token decimals)
//     4: Pay Token
//         _token: The address of the specified ERC-20 (BEP-20) token.
//         _account: the account or smart contract address you want to pay the specified token pay to.
//         _value: the amount of the specified token you want to pay. (trailing zeros for the token decimals)
//     5: Pay BNB
//         _account: the account or smart contract address you want to pay BNB token pay to.
//         _value: the amount of BNB token you want to pay. (trailing zeros for BNB decimals)
//     6: Approve Pay IoVT
//         _account: the account or smart contract you want to delegate to.
//         _value: the amount of IoVT token you want to delegate to spend. (trailing zeros for the token decimals)
//     7: Pay Delegated IoVT
//         _account: The account or smart contract that you want to pay IoVT token to pay to on behalf of the _sender.
//         _token: The account or smart contract that delegated IoVGC consortium to pay IoVT token.
//         _value: The amount of IoVT token you want to pay to the _account on behalf of the _sender.
//     11: Change Consortium (Transfer Members)
//         _account: The new IoVGC consortium smart contract.
//     12: Only Change Consortium
//         _account: The new IoVGC consortium smart contract.
//     13: Block Account
//         _account: The account you want to be blocked.
//     14: Unblock Account 
//         _account: The account you want to be unblocked.
//     15: Free Voting
//         n/a
//     16: Send Data
//         _account: Address of the specified smart contract that you want to send its function request.
//     17: Change Distributor Target Address
//         _account: The new address for target address.
//         _token: Address of the distributor smart contract.
//         _value: The target address portion id.
//     18: Change DistributorOwner
//         _account: The address of new IoGC consortium.
//         _token: The address of the distributor smart contract.
    function getProposal(uint _proposalId) public view returns(
        uint8 _approved,
        uint24 _approversCount,
        uint24 _rejectorsCount,
        uint8 _pType,
        string memory _description,
        address payable _account,
        address _token,
        uint _value,
        string memory _name
    ) {
        require(_proposalId < proposals.length, message6);
        Proposal memory _proposal = proposals[_proposalId];
        _approved = _proposal.approved;
        if (_approved == 1 && _proposal.offerTime+maxVotingDuration < uint40(block.timestamp))
            _approved = 4;
        _approversCount = _proposal.approversCount;
        _rejectorsCount = _proposal.rejectorsCount;
        _pType = _proposal.pType;
        _description = _proposal.description;
        _account = _proposal.account;
        _token = _proposal.token;
        _value = _proposal.value;
        _name = _proposal.name;
    }

// Call this function to get the members and their votes to the specified proposal.
// Input(s):
//     _proposalId: The propsal id: an ordinal number starting with 0.
// Output(s):
//     _votersNames: The array of members name.
//     _votersAddresses: The array of members address.
//     _votes: The array of the members votes:
//         0: Not voted
//         2: Approved
//         3: Rejected
    function getProposalVoters(uint _proposalId) public view returns(
        string[] memory _votersNames,
        address[] memory _votersAddresses,
        uint8[] memory _votes
    ) {
        _votersNames = new string[](membersCount);
        _votersAddresses = new address[](membersCount);
        _votes = new uint8[](membersCount);
        uint j = 0;
        for (uint i = 0; i < memberAddresses.length; i++) {
            address _memberAddress = memberAddresses[i];
            if (_memberAddress != address(0) && members[_memberAddress].isMember && proposals[_proposalId].votes[_memberAddress] > 0) {
                _votersNames[j] = members[_memberAddress].name;
                _votersAddresses[j] = _memberAddress;
                _votes[j] = proposals[_proposalId].votes[_memberAddress];
                j++;
            }
        }
    }

// Call this function to get open proposal ids.
// Open proposals is proposals that is ready for voting. So it cannot be finally approved, rejected or expired.
// Output(s):
//     _openProposals: The array of open proposal ids.
    function getOpenProposalIds() public view returns(uint[] memory _openProposals) {
        uint i;
        uint j = openProposals.length;
        for (i = 0; i < openProposals.length; i++)
            if (proposals[openProposals[i]].offerTime+maxVotingDuration < uint40(block.timestamp))
                j--;
        _openProposals = new uint[](j);
        j = 0;
        for (i = 0; i < openProposals.length; i++)
            if (proposals[openProposals[i]].offerTime+maxVotingDuration >= uint40(block.timestamp)) {
                _openProposals[j] = openProposals[i];
                j++;
            }
        return(_openProposals);
    }

}
