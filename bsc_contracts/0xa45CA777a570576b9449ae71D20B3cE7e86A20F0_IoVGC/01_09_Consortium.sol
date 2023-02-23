pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;
// SPDX-License-Identifier: MIT

// BNB Smart Chain Testnet: 0x43995D3CFcaD6feD4e42ff5A1FABe1fe3C860637
// BNB Smart Chain Mainnet: 0xa45CA777a570576b9449ae71D20B3cE7e86A20F0

import "./SafeMath.sol";
import "./Utils.sol";
import "./iDistributor.sol";
import "./ConsortiumData.sol";
import "./Proxy.sol";

// This contract is used for IoVGC (Internet of Vehicles Global Consortium)
// This consortium owns the initial IoVT tokens.
// All payments and another operations in this consortium must be decided between consortium members.
// First of decision a consortium member propose this decision to the contract and another members can approve or reject this proposal.
// If at least 2/3 of all members approve the proposal, it finally will be approved.
// If more than 1/3 of all members reject the proposal, it finally will be rejected.
// If more than 30 days passes from the proposal time, it finally will be expired.
// Before the final approval or rejection of the proposal at most during the 30 days after the proposal time,
//   members can accept or reject the proposal, or change their votes.
// Members also propose to add a new member, remove a current member or change the IoVGC consortium contract.
contract IoVGC is ConsortiumData, Proxy {
    using Strings for string;
    using SafeMath for uint;

    //****************************************************************************
    //* Events
    //****************************************************************************
    event ProposalSubmitted(uint indexed _proposalId);
    event ProposalVoted(uint indexed _proposalId, address indexed _memberAddress);
    event ProposalApproved(uint indexed _proposalId);
    event ProposalRejected(uint indexed _proposalId);
    event ProposalExpired(uint indexed _proposalId);
    event NewMemberAdded(uint indexed _proposalId, address indexed _newMember);
    event MemberRemoved(uint indexed _proposalId, address indexed _removedMember);
    event ConsortiunChanged(uint indexed _proposalId, address indexed _newConsortium);
    event FreeVotingApproved(uint indexed _proposalId, string _description);
    event SendDataApproved(uint indexed _proposalId, string _description);

    //****************************************************************************
    //* Modifiers
    //****************************************************************************
    modifier isConsortium {
        require(IoVT.getOwner() == address(this), "This contract is not consortium.");
        _;
    }
    
    modifier isMember {
        require(members[msg.sender].isMember, "You are not member of IoVGC.");
        _;
    }

    modifier isProposalIdValid(uint _proposalId) {
        require(_proposalId < proposals.length, message6);
        _;
    }

    modifier isDescriptionValid(string memory _description) {
        require(! _description.compare(""), "Invalid description.");
        _;
    }

    modifier isNameValid(string memory _name) {
        require(! _name.compare(""), "Invalid name.");
        _;
    }

    modifier isAddressValid(address _member) {
        require(_member != address(0), "Invalid member address");
        _;
    }

    modifier isValueValid(uint _value) {
        require(_value > 0, "Invalid value.");
        _;
    }

    modifier isIoVTSet {
        require(IoVTAddress != address(0), "IoVT Address is not set.");
        _;
    }

    //****************************************************************************
    //* Main Functions
    //****************************************************************************
    constructor() public {
        memberAddresses.push(msg.sender);
        membersCount = 1;
        members[msg.sender] = Member({
            name: "Creator",
            isMember: true,
            id: 0
        });
    }

// Use this function after deploying the contract. This function sets the IoVT token address.
// Only IoVGC consortium members can send this function.
// Input(s):
//     _IoVTAddress: The address of IoVT token.
    function setIoVTAddress(address _IoVTAddress) public isMember isAddressValid(_IoVTAddress) {
        require(IoVTAddress == address(0), "You set IoVT address before.");
        IoVTAddress = _IoVTAddress;
        IoVT = iERC20(IoVTAddress);
    }

// Use this function to propose adding a new member to the consortium.
// Only IoVGC consortium members can send this function.
// Input(s):
//     _dscription: The description about this proposal.
//     _member: The account address of the proposed new member.
//     _name: The name of the proposed new member.
    function proposeAddMember(string memory _description, string memory _name, address payable _member) public isMember isConsortium isNameValid(_name) isAddressValid(_member) {
        require(! members[_member].isMember, message4);
        _registerProposal(1, _description, _member, address(0), 0, _name, "");
    }

// Use this function to propose removing a current member of the consortium.
// Only IoVGC consortium members can send this function.
//     _dscription: The description about this proposal.
//     _member: The account of the proposed member to be removed.
    function proposeRemoveMember(string memory _description, address payable _member) public isMember isConsortium isAddressValid(_member) {
        require(members[_member].isMember, message7);
        require(membersCount > 1, message13);
        _registerProposal(2, _description, _member, address(0), 0, members[_member].name, "");
    }

// Use this function to propose paying IoVT token (set in IoVTAddress() ) to a specified account or smart contract.
// In executing this proposal, if the receiver account will be a distributor contract, then the function registerReceivedValue() 
//   of distributor contract would be run automatically.
// Only IoVGC consortium members can send this function.
// Input(s):
//     _dscription: The description about this proposal.
//     _account: the account or smart contract address you want to pay IoVT token pay to.
//     _value: the amount of IoVT token you want to pay. (trailing zeros for the token decimals)
    function proposePayIoVT(string memory _description, address payable _account, uint _value) public isMember isConsortium isIoVTSet isAddressValid(_account) isValueValid(_value) {
        require(_value <= IoVT.balanceOf(address(this)), message1);
        _registerProposal(3, _description, _account, address(0), _value, "", "");
    }

// Use this function to propose paying any ERC-20 (BEP-20) token to a specified account or smart contract.
// Only IoVGC consortium members can send this function.
// Input(s):
//     _dscription: The description about this proposal.
//     _tokenAddress: The address of the specified ERC-20 (BEP-20) token.
//     _account: the account or smart contract address you want to pay the specified token pay to.
//     _value: the amount of the specified token you want to pay. (trailing zeros for the token decimals)
    function proposePayToken(string memory _description, address _tokenAddress, address payable _account, uint _value) public isMember isConsortium isAddressValid(_account) isValueValid(_value) {
        require(_tokenAddress != address(0), message8);
        try iERC20(_tokenAddress).balanceOf(address(this)) returns(uint _balance) {
            require(_value <= _balance, message1);
        }
        catch {
            revert(message8);
        }
        _registerProposal(4, _description, _account, _tokenAddress, _value, "", "");
    }

// Use this function to propose paying BNB token to a specified account or smart contract.
// Only IoVGC consortium members can send this function.
// Input(s):
//     _dscription: The description about this proposal.
//     _account: the account or smart contract address you want to pay BNB token pay to.
//     _value: the amount of BNB token you want to pay. (trailing zeros for BNB decimals)
    function proposePayBNB(string memory _description, address payable _account, uint _value) public isMember isConsortium isAddressValid(_account) isValueValid(_value) {
        require(_value <= address(this).balance, message1);
        _registerProposal(5, _description, _account, address(0), _value, "", "");
    }

// Use this function to propose delegating to an account or smart contract to pay the specified IoVT token amount from the IoVGC consortium contract.
// Only IoVGC consortium members can send this function.
// Input(s):
//     _dscription: The description about this proposal.
//     _spender: the account or smart contract you want to delegate to.
//     _value: the amount of IoVT token you want to delegate to spend. (trailing zeros for the token decimals)
    function proposeApprovePayIoVT(string memory _description, address payable _spender, uint _value) public isMember isConsortium isIoVTSet isAddressValid(_spender) isValueValid(_value) {
        require(_value <= IoVT.balanceOf(address(this)), message1);
        _registerProposal(6, _description, _spender, address(0), _value, "", "");
    }

// Use this function to propose paying the specified amount of IoVT token on behalf of an account or smart contract the delegates IoVGC consortium to pay.
// Only IoVGC consortium members can send this function.
// Input(s):
//     _dscription: The description about this proposal.
//     _sender: The account or smart contract that delegated IoVGC consortium to pay IoVT token.
//     _account: The account or smart contract that you want to pay IoVT token to pay to on behalf of the _sender.
//     _value: The amount of IoVT token you want to pay to the _account on behalf of the _sender.
    function proposePayDelegatedIoVT(string memory _description, address payable _sender, address payable _account, uint _value) public isMember isConsortium isIoVTSet {
        require(_value <= IoVT.balanceOf(_sender), message1);
        _registerProposal(7, _description, _account, _sender, _value, "", "");
    }
    
// Use this function to propose changing the IoVGC consortium smart contract. 
// Executing this proposal:
//     1: Copies all of current consortium members to the new contract.
//     2: Transfer all of the IoVT token amount from this cotract to the new contract.
//     3: Change the owner of IoVT token contract to the new contract.
//     4: So the new contract will be IoVGC consortium contract.
// After executing this proposal, this contract will not any rights and abilities to the IoVT token and none of this contract members can propose or vote.
// Only IoVGC consortium members can send this function.
// Input(s):
//     _dscription: The description about this proposal.
//     _consortium: The new IoVGC consortium smart contract.
    function proposeChangeCosortium(string memory _description, address payable _consortium) public isMember isConsortium isIoVTSet isAddressValid(_consortium) {
        _checkNewConsortium(_consortium);
        _registerProposal(11, _description, _consortium, address(0), 0, "", "");
    }

// Use this function to propose changing the IoVGC consortium smart contract. 
// Executing this proposal:
//     1: Copies all of current consortium members to the new contract.
//     2: Change the owner of IoVT token contract to the new contract.
//     3: So the new contract will be IoVGC consortium contract.
// Note that executing this proposal will not copy the current consortium members to the new contract.
// After executing this proposal, this contract will not any rights and abilities to the IoVT token and none of this contract members can propose or vote.
// Only IoVGC consortium members can send this function.
// Input(s):
//     _dscription: The description about this proposal.
//     _consortium: The new IoVGC consortium smart contract.
    function proposeChangeCosortiumWithoutMembers(string memory _description, address payable _consortium) public isMember isConsortium isIoVTSet isAddressValid(_consortium) {
        _checkNewConsortium(_consortium);
        _registerProposal(12, _description, _consortium, address(0), 0, "", "");
    }

// Use this function to propose blocking a specified account in the IoVT token contract.
// A blocked account cannot send IoVT tokens directly or by a delegated account.
// Only IoVGC consortium members can send this function.
// Input(s):
//     _dscription: The description about this proposal.
//     _account: The account you want to be blocked.
    function proposeBlockAccount(string memory _description, address payable _account) public isMember isConsortium isAddressValid(_account) {
        require(! IoVT.isAccountBlocked(_account), message5);
        _registerProposal(13, _description, _account, address(0), 0, "", "");
    }

// Use this function to propose unblocking a specified account in the IoVT token contract.
// Unblocking an account will free it from blocked state. A blocked account cannot send IoVT tokens directly or by a delegated account.
// Only IoVGC consortium members can send this function.
// Input(s):
//     _dscription: The description about this proposal.
//     _account: The account you want to be unblocked.
    function proposeUnlockAccount(string memory _description, address payable _account) public isMember isConsortium isAddressValid(_account) {
        require(IoVT.isAccountBlocked(_account), message9);
        _registerProposal(14, _description, _account, address(0), 0, "", "");
    }

// Use this function to propose a free voting.
// Free voting only operate a voting without any operation in blockchain. You can see only the result of voting an its voters.
// Only IoVGC consortium members can send this function.
// Input(s):
//     _dscription: The description about this proposal.
    function proposeFreeVoting(string memory _description) public isMember isConsortium {
        _registerProposal(15, _description, address(0), address(0), 0, "", "");
    }

// Use this function to propose sending data to smart contract.
// By executing this proposal you can run any function from another smart contracts if they permitted.
// Only IoVGC consortium members can send this function.
// Note that in executing this proposal all of the outputs will be omitted.
// Input(s):
//     _dscription: The description about this proposal.
//     _smartContractAddress: Address of the specified smart contract that you want to send its function request.
//     _data: The data can you send to the _smartContractAddress. This data must be equivalent to the output of abi.encodeWithSignature() function.
    function proposeSendData(string memory _description, address payable _smartContractAddress, bytes memory _data, uint _value) public isMember isConsortium isAddressValid(_smartContractAddress) {
        _registerProposal(16, _description, _smartContractAddress, address(0), _value, "", _data);
    }

// Use this function to propose changing of one of the target addresses in distributor smart contract.
// A distributor smart contract is a contract that you can pay IoVT token to it and it will pay it to target addresses after its release time.
// Distributor smart contract consists of some portions. Each portion is consist of:
//     1: Portion Id: An ordinal number starting with 0.
//     2: Payment Value: The total payment of this portion.
//     3: Target Address: An address that the share will pay to.
//     4: Release Time: The time that the portion share will release. At first of after release time, the target address will 
//        receive the its first share.
//     5: Number of Quarters: All of the payment value will be divided into the number of quarters, the result will be paid to the
//        target address after each quarter next to the release time.
// By executing this proposal you can change one of its target addresses, so the new address can receive the payments.
// Note that you may have multiple distributor smart contracts simultaneously.
// Only IoVGC consortium members can send this function.
// Input(s):
//     _dscription: The description about this proposal.
//     _distributorContract: Address of the distributor smart contract.
//     _portionId: The target address portion id.
//     _targetAccount: The new address for target address.
    function proposeChangeDistributorTargetAddress(string memory _description, address payable _distributorContract, uint _portionId, address payable _targetAccount) public isMember isConsortium isAddressValid(_distributorContract) isAddressValid(_targetAccount) {
        try iDistributor(_distributorContract).getOwner() returns(address _owner) {
            require(_owner == address(this), message14);
        }
        catch {
            revert(message15);
        }
        try iDistributor(_distributorContract).getPortionsCount() returns(uint _portionsCount) {
            require(_portionId < _portionsCount, message2);
        }
        catch {
            revert(message15);
        }
        _registerProposal(17, _description, _targetAccount, _distributorContract, _portionId, "", "");
    }
    
// Use this function to propose changing of distributor contract owner.
// This operation is used just before changing the IoVGC consortium contract and sets the new consortium contract address as the distributor owner.
// Only IoVGC consortium members can send this function.
// Input(s):
//     _dscription: The description about this proposal.
//     _distributorContract: The address of the distributor smart contract.
//     _newConsortium: The address of new IoGC consortium.
    function proposeChangeDistributorOwner(string memory _description, address payable _distributorContract, address payable _newConsortium) public isMember isConsortium isAddressValid(_distributorContract) isAddressValid(_newConsortium) {
        try iDistributor(_distributorContract).getOwner() returns(address _owner) {
            require(_owner == address(this), message14);
        }
        catch {
            revert(message15);
        }
        _registerProposal(18, _description, _newConsortium, _distributorContract, 0, "", "");
    }

// Use this function to vote approval to a specified proposal.
// Before final approving or rejecting this proposal voters can also change their votes.
// All votes are transparent and all people can see each vote.
// A proposal will be finally approved, if and only if at least two third (2/3) of consortium members vote to approve it.
// A proposal will be finally rejected, if and only if more than one third (1/3) of consortium members vote to reject it.
// A proposal will be finally expired, if and only if after 30 days of the proposed time, it cannot be approved or rejected.
// Only IoVGC consortium members can send this function.
// Input(s):
//     _proposalId: The proposal id that you want to approve it. Proposal id is an ordinal number starting with 0.
    function voteApprove(uint _proposalId) public isMember isConsortium isProposalIdValid(_proposalId) {
        Proposal storage _proposal = proposals[_proposalId];
        require(_proposal.approved == 1, message3);
        if (_proposal.offerTime+maxVotingDuration < uint40(block.timestamp) && _proposal.approved == 1) {
            _proposal.approved = 4;
            Utils.deleteArrayElement(openProposals, _proposalId);
        } else {
            uint8 _vote = _proposal.votes[msg.sender];
            require(_vote != 2, "You approved this proposal before.");
            _proposal.approversCount++;
            if (_vote == 3)
                _proposal.rejectorsCount--;
            _proposal.votes[msg.sender] = 2;
            emit ProposalVoted(_proposalId, msg.sender);
            _checkProposalApproval(_proposalId);
        }
    }

// Use this function to vote rejection to a specified proposal.
// Before final approving or rejecting this proposal voters can also change their votes.
// All votes are transparent and all people can see each vote.
// A proposal will be finally approved, if and only if at least two third (2/3) of consortium members vote to approve it.
// A proposal will be finally rejected, if and only if more than one third (1/3) of consortium members vote to reject it.
// A proposal will be finally expired, if and only if after 30 days of the proposed time, it cannot be approved or rejected.
// Only IoVGC consortium members can send this function.
// Input(s):
//     _proposalId: The proposal id that you want to reject it. Proposal id is an ordinal number starting with 0.
    function voteReject(uint _proposalId) public isMember isConsortium isProposalIdValid(_proposalId) {
        Proposal storage _proposal = proposals[_proposalId];
        require(_proposal.approved == 1, message3);
        if (_proposal.offerTime+maxVotingDuration < uint40(block.timestamp) && _proposal.approved == 1) {
            _proposal.approved = 4;
            emit ProposalExpired(_proposalId);
            Utils.deleteArrayElement(openProposals, _proposalId);
        } else {
            uint8 _vote = _proposal.votes[msg.sender];
            require(_vote != 3, "You rejected this proposal before.");
            _proposal.rejectorsCount++;
            if (_vote == 2)
                _proposal.approversCount--;
            _proposal.votes[msg.sender] = 3;
            emit ProposalVoted(_proposalId, msg.sender);
            _checkProposalApproval(_proposalId);
        }
    }

// You cannot use this function. When changing the consortium contract, this function will be sent automatically from the 
//   new IoVGC consortium by the old one to copy members from the old consortium to the new one.
    function pullMembers(string[] memory _names, address[] memory _addresses, uint24[] memory _ids) public {
        require(msg.sender == IoVT.getOwner(), "You are not authorized to call this function.");
        uint _currentMembersCount = memberAddresses.length;
        uint _newMembersCount = _names.length;
        membersCount = uint24(_newMembersCount);
        uint i;
        address _memberAddress;
        for (i = 0; i < _currentMembersCount; i++) {
            _memberAddress = memberAddresses[i];
            if (_memberAddress != address(0)) {
                members[_memberAddress].isMember = false;
                memberAddresses[i] = address(0);
            }
        }
        uint j = 0;
        uint _id;
        for (i = 0; i < _newMembersCount; i++) {
            _id = _ids[i];
            while (j < _id) {
                if (j >= _currentMembersCount)
                    memberAddresses.push(address(0));
                j++;
            }
            memberAddresses.push(_addresses[i]);
            members[_addresses[i]] = Member({
                name: _names[i],
                isMember: true,
                id: uint24(_id)
            });
        }
    }

    //****************************************************************************
    //* Internal Functions
    //****************************************************************************
    function _checkProposalApproval(uint _proposalId) internal {
        Proposal storage _proposal = proposals[_proposalId];
        if (uint(_proposal.approversCount) >= uint(membersCount).mul(quorumCoefficient).sub(1).div(quorumDivisor).add(1)) {
            _proposal.approved = 2;
            _executeProposal(_proposalId);
            emit ProposalApproved(_proposalId);
            Utils.deleteArrayElement(openProposals, _proposalId);
        }
        else if (_proposal.rejectorsCount > uint(membersCount).mul(quorumDivisor-quorumCoefficient).div(quorumDivisor)) {
            _proposal.approved = 3;
            emit ProposalRejected(_proposalId);
            Utils.deleteArrayElement(openProposals, _proposalId);
        }
    }

    function _executeProposal(uint _proposalId) internal {
        Proposal memory _proposal = proposals[_proposalId];
        if (_proposal.pType == 1) { // Add Member
            require(! members[_proposal.account].isMember, message4);
            memberAddresses.push(_proposal.account);
            membersCount++;
            members[_proposal.account] = Member({
                name: _proposal.name,
                isMember: true,
                id: uint24(memberAddresses.length - 1)
            });
            emit NewMemberAdded(_proposalId, _proposal.account);
        }
        else if (_proposal.pType == 2) { // Remove Member
            require(members[_proposal.account].isMember, message7);
            require(membersCount > 1, message13);
            delete memberAddresses[members[_proposal.account].id];
            membersCount--;
            members[_proposal.account].isMember = false;
            emit MemberRemoved(_proposalId, _proposal.account);
        }
        else if (_proposal.pType == 3) { // Pay IoVT
            require(_proposal.value <= IoVT.balanceOf(address(this)), message1);
            IoVT.transfer(_proposal.account, _proposal.value);
            try iDistributor(_proposal.account).registerReceivedValue() {}
            catch {}
        }
        else if (_proposal.pType == 4) { // Pay Token
            iERC20 _token = iERC20(_proposal.token);
            try _token.balanceOf(address(this)) returns(uint _balance) {
                require(_proposal.value <= _balance, message1);
            }
            catch {
                revert(message8);
            }
            _token.transfer(_proposal.account, _proposal.value);
        }
        else if (_proposal.pType == 5) { // Pay BNB
            require(_proposal.value <= address(this).balance, message1);
            _proposal.account.transfer(_proposal.value);
        }
        else if (_proposal.pType == 6) { // Approve Pay IoVT
            require(_proposal.value <= IoVT.balanceOf(address(this)), message1);
            IoVT.approve(_proposal.account, _proposal.value);
        }
        else if (_proposal.pType == 7) { // Pay Delegated IoVT
            require(_proposal.value <= IoVT.balanceOf(_proposal.token), message1);
            IoVT.transferFrom(_proposal.token, _proposal.account, _proposal.value);
        }
        else if (_proposal.pType == 11) { // Change Consortium
            _transferAssets(_proposal.account);
            _pushMembers(_proposal.account);
            IoVT.changeOwner(_proposal.account);
            emit ConsortiunChanged(_proposalId, _proposal.account);
        }
        else if (_proposal.pType == 12) { // Change Consortium Without Members
            _transferAssets(_proposal.account);
            IoVT.changeOwner(_proposal.account);
            emit ConsortiunChanged(_proposalId, _proposal.account);
        }
        else if (_proposal.pType == 13) { // Block Account
            require(! IoVT.isAccountBlocked(_proposal.account), message5);
            IoVT.blockAccount(_proposal.account);
        }
        else if (_proposal.pType == 14) { // Unblock Account
            require(IoVT.isAccountBlocked(_proposal.account), message9);
           IoVT.unblockAccount(_proposal.account);
        }
        else if (_proposal.pType == 15) { // Free Voting
            emit FreeVotingApproved(_proposalId, _proposal.description);
        }
        else if (_proposal.pType == 16) { // Send Data
            (bool _success, /*bytes memory _returnData*/) = _proposal.account.call{value: _proposal.value}(_proposal.data);
            require(_success);
            emit SendDataApproved(_proposalId, _proposal.description);
        }
        else if (_proposal.pType == 17) { // Change Distributor Target Address
            iDistributor(_proposal.token).setReceiverAccount(uint8(_proposal.value), _proposal.account);
        }
        else if (_proposal.pType == 18) { // Change Distributor Owner
            iDistributor(_proposal.token).changeOwner(_proposal.account);
        }
    }

    function _registerProposal(
        uint8 _pType, 
        string memory _description, 
        address payable _account, 
        address _token, 
        uint _value, 
        string memory _name, 
        bytes memory _data
        ) internal isDescriptionValid(_description) {
        proposals.push(Proposal({
            approved: 1,
            approversCount: 1,
            rejectorsCount: 0,
            pType: _pType,
            description: _description,
            account: _account,
            token: _token,
            value: _value,
            name: _name,
            data: _data,
            offerTime: uint40(block.timestamp)
        }));
        uint _proposalId = proposals.length-1;
        openProposals.push(_proposalId);
        proposals[_proposalId].votes[msg.sender] = 2;
        emit ProposalSubmitted(_proposalId);
        _checkProposalApproval(_proposalId);
    }

    function _pushMembers(address _newConsortium) internal {
        (string[] memory _names, address[] memory _addresses, uint24[] memory _ids) = getMembers();
        IoVGC(_newConsortium).pullMembers(_names, _addresses, _ids);
    }

    function _checkNewConsortium(address _consortium) internal {
        require(IoVGC(_consortium).IoVTAddress() == IoVTAddress, message10);
        require(_consortium != address(this), "New consortium contract required.");
        try IoVGC(_consortium).name() returns(string memory _name) {
            require(_name.compare(name), message11);
        }
        catch {
            revert(message11);
        }
        try IoVGC(_consortium).version() returns(string memory _version) {
            require(Utils.compareVersion(version, _version), "Consortium contract version is old.");
        }
        catch {
            revert(message11);
        }
        string[] memory _names;
        address[] memory _addresses;
        uint24[] memory _ids;
        try IoVGC(_consortium).pullMembers(_names, _addresses, _ids) {

        } catch {
            revert("Invalid or not configured consortium contract.");
        }
    }

    function _transferAssets(address payable _account) internal {
        require(IoVGC(_account).IoVTAddress() == IoVTAddress, message10);
        uint _IoVTBalance = IoVT.balanceOf(address(this));
        if (_IoVTBalance > 0)
            IoVT.transfer(_account, _IoVTBalance);
        if (address(this).balance > 0)
            _account.transfer(address(this).balance);
    }

    //****************************************************************************
    //* Getter Functions
    //****************************************************************************
// Call this function to get the consortium members specifications in the output.
// Output(s):
//     _names: The array of the names of the consortium members.
//     _addresses: The array of the addresses of the consortium members.
//     _ids: The array of the ids of the consortium members.
    function getMembers() public view returns(string[] memory _names, address[] memory _addresses, uint24[] memory _ids) {
        membersCount;
        _names = new string[](membersCount);
        _addresses = new address[](membersCount);
        _ids = new uint24[](membersCount);
        uint j = 0;
        for (uint i = 0; i < memberAddresses.length; i++) {
            address _memberAddress = memberAddresses[i];
            if (_memberAddress != address(0) && members[_memberAddress].isMember) {
                Member memory _member = members[_memberAddress];
                _names[j] = _member.name;
                _addresses[j] = _memberAddress;
                _ids[j] = _member.id;
                j++;
            }
        }
    }

// These functions are executables from the delegated smart contract.
// If you want to use this function from web3 interfaces, you should omit starting and ending comment signs below (/* & */) 
//   and compile it for using abi json code in web3 interfaces.
/*

// Call this function to get the number of the consortium members.
// Output(s):
//     -Returns the number of the consortium members.
    function getMembersCount() public view returns(uint24) {
    }

// Call this function to determine if the caller account is member of the IoVGC consortium.
// Output(s):
//     -Returns true if the caller account is member of the consortium, otherwise false.
    function AmIMember() public view returns(bool) {
    }

// Call this function to get an IoVGC consortium member specifications by giving the specified member id.
// Input(s):
//     _memberId: The member id. Member id is an ordinal number starting with 0.
// Output(s):
//     _name: The name of the specified member.
//     _memberAddress: The address of the specified member.
    function getMemberById(uint _memberId) public view returns(string memory _name, address _memberAddress) {
    }

// Call this function to get an IoVGC consortium member specifications by giving the specified member address.
// Input(s):
//     _memberId: The member id. Member id is an ordinal number starting with 0.
// Output(s):
//     _name: The name of the specified member.
//     _memberId: The id of the specified member.
    function getMemberByAddress(address _memberAddress) public view returns(string memory _name, uint24 _memberId) {
    }

// Call this function to get the number of the offered proposals.
// Note that if you get n as the output of this function, then you can use 0 to n-1 as the proposal id in another functions.
// Output(s):
//     -Returns the number of the offered proposals.
    function getProposalsCount() public view returns(uint) {
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
    }

// Call this function to get open proposal ids.
// Open proposals is proposals that is ready for voting. So it cannot be finally approved, rejected or expired.
// Output(s):
//     _openProposals: The array of open proposal ids.
    function getOpenProposalIds() public view returns(uint[] memory _openProposals) {
    }
*/

}