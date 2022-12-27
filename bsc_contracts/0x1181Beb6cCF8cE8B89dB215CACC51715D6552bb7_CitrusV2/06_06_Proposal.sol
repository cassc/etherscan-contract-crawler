// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;
import "./Owner.sol";
import "./Bep20.sol";

contract Proposal is Owned, BEP20 {

    /**
     * Basic Structure of Proposal
     * description :- What is the purpose of this proposal 
     * proposalByOwner :- address of the Owner Who is propose 
     * recipient :- this is used for add owner, remove owner, also which address you want to transfer funds  
     * amount :- Amount you want to transfer to the recipient
     * isCompleted :- Proposal is completed or not 
     * noOfVoters :- no of owners vote for proposal
     * lockTime :- After complete proposal for this time owner wallet lock for lockTime periods
     * typeOfProposal :- 0 for transfer, 1 for add Owner, 2 for remove Owner, 3 for burning, 4 for emergency
     * voters :- it is for checking if owner voted or not
     */
     
    struct Proposals {
        string description;
        address proposalByOwner;
        address payable recipient;
        uint256 amount;
        bool isCompleted;
        uint256 noOfVoters;
        uint256 lockTime;
        ProposalType typeOfProposal; 
        mapping(address => bool) voters;
    }

    enum ProposalType{
        Transfer, //0
        AddOwner, //1
        RemoveOwner, //2
        Burn, //3
        Emergency //4
    }

    uint256 public numProposals;  // till now number of Proposal is made
    mapping(uint256 => Proposals) public proposals; // for checking Poposal to all Users 
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // for Checking Who is voted Agree or not Agree
    bool public isSuccess; 
    mapping (uint256 => mapping(address => bool)) history;
    uint256 public lockTimeForOwners;

    /**
      Emited when Proposal will be created
     */

    event CreateProposalEvent(
        string description,
        address recipient,
        uint256 value,
        ProposalType typeOfProposal
    );

    event Vote(
        address owner,
        uint256 indexed proposal,
        bool vote
    );

    event Approve(
        address owner,
        address recipient,
        uint256 value,
        uint256 lockTime,
        uint256 indexed proposal,
        ProposalType typeOfProposal
    );

    /**
      function for Creating Proposals 
      only owners can create Proposals
      check Basic Structure of Proposals for more info
     */

    function createProposal(
        string memory _description,
        uint256 _value, //Numberic value for transfer, burn or emergency else pass 0.
        address payable _recipient, 
        ProposalType _typeOfProposal
    ) 
        external
        onlyOwners 
    {
        Proposals storage newProposal = proposals[numProposals++];
        newProposal.description = _description;
        newProposal.amount = _value;
        newProposal.recipient = _recipient;
        newProposal.isCompleted = false;
        newProposal.noOfVoters = 0;
        newProposal.lockTime = lockTime[msg.sender];
        newProposal.typeOfProposal = _typeOfProposal;
        newProposal.proposalByOwner = msg.sender;
        // lockTime[msg.sender] = block.timestamp + LOCK_TIME;
        
        emit CreateProposalEvent(
            _description,
            _recipient,
            _value,
            _typeOfProposal
        );
    }
    
    /**
      function for Voting Proposals 
      only owners can vote for it Proposals
      _index :- it's index of proposals. eg. mapping(_index => Proposals) public proposals;
      _isVote :- true(1), false(0)
     */

    function voteForProposal(
        uint256 _index, 
        bool _isVote
    )
        external
        onlyOwners
    {
        Proposals storage thisProposal = proposals[_index];
        require(!thisProposal.voters[msg.sender], "PROMPT 2011: Already voted for this request!");
        thisProposal.voters[msg.sender] = _isVote;
        if (_isVote) 
            thisProposal.noOfVoters++;
            proposalVotes[_index][msg.sender] = _isVote;
        
        emit Vote(msg.sender, _index, _isVote);

    }

    /**
      function for Approve Proposals 
      only owners can Approve Proposals
     */

    function approveProposal(
        uint256 _index //Index of created proposal
    ) 
        external
        onlyOwners 
    {
        Proposals storage thisProposal = proposals[_index];
        require(!thisProposal.isCompleted, "PROMPT 2012: Request already completed!");
        require(thisProposal.noOfVoters == noOfOwners, "PROMPT 2013: All owner must be voted for approval. Please try after voting is completed by all owners!"); //Needs 100% vote for approval
        require(thisProposal.proposalByOwner == msg.sender, "PROMPT 2014: Access denied! You are not the Owner of the Request!");
        
        if (thisProposal.typeOfProposal == ProposalType.Transfer) {
            lockTime[msg.sender] = 0;
            transfer(thisProposal.recipient,thisProposal.amount);
            
        } else if (thisProposal.typeOfProposal == ProposalType.AddOwner) {
            addOwner(thisProposal.recipient);

        } else if (thisProposal.typeOfProposal == ProposalType.RemoveOwner) {
            removeOwner(thisProposal.recipient);
            removeVoteByOwner(thisProposal.recipient);


        } else if (thisProposal.typeOfProposal == ProposalType.Burn) {  
            _burn(msg.sender, thisProposal.amount);

        } else if (thisProposal.typeOfProposal == ProposalType.Emergency) {
            lockTime[msg.sender] = 0;
            transfer(thisProposal.recipient,thisProposal.amount);
        }

        isSuccess = true;
        if (isSuccess)
            lockTime[msg.sender] = lockTimeForOwners;
            thisProposal.isCompleted = true;
            isSuccess = false;
            emit Approve(msg.sender, thisProposal.recipient, thisProposal.amount, thisProposal.lockTime, _index, thisProposal.typeOfProposal);
    }   


    function removeVoteByOwner(address _recipient) internal{
        for (uint256 i=0; i<=numProposals; i++){
            Proposals storage thisProposal = proposals[i];
            if (thisProposal.voters[_recipient]){
                history[i][_recipient] = proposalVotes[i][_recipient];
                proposalVotes[i][_recipient] = false;
                thisProposal.noOfVoters--;
            }else{
                history[i][_recipient] = proposalVotes[i][_recipient];
            }
        }
    }

    function getHistory(uint256 _index, address _owner) external view returns(bool){
        return history[_index][_owner];
    }
}